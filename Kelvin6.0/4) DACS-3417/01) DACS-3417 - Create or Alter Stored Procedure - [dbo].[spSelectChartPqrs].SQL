------------------------------------------------------------------------------------
-- 01) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectChartPqrs].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectChartPqrs', @DestProc = 'spSelectChartPqrs_DACS-3417';
GO

CREATE OR ALTER PROCEDURE [dbo].[spSelectChartPqrs] 
	@ChartId INT,
	@MeasureId INT = NULL,
	@MeasureCodeId INT = NULL
	WITH
EXEC AS CALLER AS

------------------------------------------------------------------------------------
-- Adds additional CODING_SYSTEM strings used within the various temporary tables to allow for extended behavior supporting new MIPS decision logic - DACS-3164 - 20240422 - pippin
------------------------------------------------------------------------------------

-- testing
-- DECLARE @ChartId INT = 2100107114;
-- DECLARE @MeasureId INT = NULL;
-- DECLARE @MeasureCodeId INT = NULL;
-- body of original SPROC -- >

DECLARE @chart_id INT = @ChartId;
DECLARE @measure_id INT = @MeasureId;
DECLARE @measure_code_id INT = @MeasureCodeId;
DECLARE @Now DATETIME = GETDATE();
DECLARE @flag VARCHAR(10) = '';
DECLARE @HasDXCode INT;
DECLARE @HasCPTCode INT;

Declare @PSP_CPT varchar(50)	-- added 2/21/2023 (dsexton)

-- Drop statements for new temp tables added 2/21/2023 (dsexton)
if object_id('TempDB..#MeasureList', 'U') is not null DROP TABLE #MeasureList;
if object_id('TempDB..#RequireCptMeasures', 'U') is not null DROP TABLE #RequireCptMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures;
if object_id('TempDB..#RequiredDiagnosisMeasures2', 'U') is not null DROP TABLE #RequiredDiagnosisMeasures2;
if object_id('TempDB..#RequiredMeasures2', 'U') is not null DROP TABLE #RequiredMeasures2;
if object_id('TempDB..#RequiredMeasuresOldLogic', 'U') is not null DROP TABLE #RequiredMeasuresOldLogic;
if object_id('TempDB..#Chart', 'U') is not null DROP TABLE #Chart;
--if object_id('TempDB..#ChartDiagCode9', 'U') is not null DROP TABLE #ChartDiagCode9;	-- DACS-3417, 08/19/2024 (pippin)
if object_id('TempDB..#ChartDiagCodeICD10', 'U') is not null DROP TABLE #ChartDiagCodeICD10;
if object_id('TempDB..#PPE_CPT', 'U') is not null DROP TABLE #PPE_CPT;

-- new temp table for tuning, 2/21/2023 (dsexton)
select chart_ID, service_agreement_ID, primary_complaint, chief_complaint, PHYSICIAN_SERVICE_PROC_ID, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
	, Time_of_Service, gender, patient_DOB, patient_age
  into #Chart	
from CHART
where chart_ID = @chart_id

-- select * from #Chart -- testing

/*
This sproc executes very frequently at certain times of the day. For example, on 2/21/2023 it executed nearly 8K times between 4:30-7:30 AM. By 3 pm it executed only an additional 3,500 times.
It is called by sproc spSelectMissingChartPqrs which has executed 37K times over the past seven days. 
Avg LReads have been 150K which adds up to several billion reads each day. 

Modified all CLR queries to instead write to temp tables, 2/21/2023 (dsexton).  This reduced logical reads 95% (13K vs 240K) when testing with chart_ID 101104526.
	-- Duration was reduced 80% (31ms vs 184ms).
*/


--WITH MeasureList						-- replaced all CLR queries with temp tables, 2/21/2023 (dsexton)
--AS (
	SELECT cpm.CMS_PQRI_MEASURE_ID,
		cpm.MEASURE_TITLE,
		cpm.REQUIRES_BOTH_CPT_AND_DX,
		cpmc.CMS_PQRI_MEASURE_CODE_ID,
		cpmc.CODING_SYSTEM,
		cpmc.OPTION_GROUP,
		cpmc.CODE,
		cpmc.MODIFIER,
		cpmc.[DESCRIPTION],
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE,
		cpmc.CODE_2,
		cpmc.MODIFIER_2,
		cpm.REQUIRES_MULTIPLE_CPTS,
		cpm.MULTIPLE_CPT_COUNT,
		cpm.REQUIRES_MULTIPLE_DX,
		cpm.REQUIRES_CPT_CODE,
		cpm.REQUIRED_CPT_CODE,
		CASE 
			WHEN COALESCE(cpm.REQUIRES_EM_ONLY, 0) = 1
				AND (c.PHYSICIAN_SERVICE_PROC_ID > 0 OR c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0)
				THEN 1
			ELSE 0
			END REQUIRES_EM_ONLY,
		CASE 
			WHEN COALESCE(cpm.MATCH_EM_LEVEL, 0) = 1
				THEN 1
			ELSE 0
			END MATCH_EM_LEVEL,
		CASE 
			WHEN cpmc.START_DATE IS NULL
				THEN '1/1/1900 00:00:00'
			ELSE cpmc.START_DATE
			END START_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE IS NULL
				THEN '02/20/2020 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		CASE 
			WHEN cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE
			END REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
	    CONVERT(Date, c.TIME_OF_SERVICE) as DATE_OF_SERVICE,
		cpm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		cpm.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #MeasureList							-- tuning, 2/21/2023 (dsexton)
	FROM CMS_PQRI_MEASURE cpm WITH (NOLOCK)
	LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc WITH (NOLOCK) ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	--INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
	cross join #Chart c		--ON c.CHART_ID = @chart_id
	WHERE DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, c.TIME_OF_SERVICE)
		AND (
			ISNULL(cpm.GENDER, 'B') = 'B'
			OR cpm.GENDER = c.GENDER
			)
		AND (
			(
				(COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) = 0
				AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0)) = 999
				)
			OR (
				(c.PATIENT_AGE IS NOT NULL AND c.PATIENT_DOB IS NULL
				AND c.PATIENT_AGE BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				))
			
			OR (
				(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NOT NULL OR cpm.TO_AGE_FRACTIONAL IS NOT NULL)
				AND ((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) BETWEEN (COALESCE(cpm.FROM_AGE, 0) + COALESCE(cpm.FROM_AGE_FRACTIONAL, 0)) AND (COALESCE(cpm.TO_AGE, 999) + COALESCE(cpm.TO_AGE_FRACTIONAL, 0))
				)
			
			OR (
			(c.PATIENT_DOB IS NOT NULL AND cpm.FROM_AGE_FRACTIONAL IS NULL AND cpm.TO_AGE_FRACTIONAL IS NULL)
				AND CAST(((CAST(c.TIME_OF_SERVICE AS INT) - CAST(c.PATIENT_DOB AS INT)) / 365.25) AS INT) BETWEEN COALESCE(cpm.FROM_AGE, 0)  AND COALESCE(cpm.TO_AGE, 999)
				)
			)

		AND cpm.CMS_PQRI_MEASURE_ID IN (
			SELECT sapqrs.CMS_PQRI_MEASURE_ID
			FROM SERVICE_AGREEMENT_PQRS sapqrs WITH (NOLOCK)
			WHERE sapqrs.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				AND CONVERT(Date, c.TIME_OF_SERVICE) BETWEEN EFFECTIVE_DATE AND ISNULL(EXPIRATION_DATE, @Now)
			)
	--),

-- select '#MeasureList' = null
-- select * from #MeasureList where measure_title like '%332%' OR measure_title like '% 7-%' -- testing


-- New objects for tuning, 2/21/2023 (dsexton)  -------------------------------------------------------------------------------
/* -- DACS-3417, 08/19/2024 (pippin)
SELECT cdc.ICD9_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, c.CHIEF_COMPLAINT, c.PRIMARY_COMPLAINT, c.Time_of_Service
  into #ChartDiagCode9
FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
*/

SELECT cdc.ICD10_CODE, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, cdc.DIAGNOSIS_TYPE_ID, cdc.IS_PRIMARY, c.Time_of_Service
  into #ChartDiagCodeICD10
FROM CHART_DIAGNOSIS_CODE_ICD10 cdc WITH (NOLOCK)
INNER JOIN #Chart c ON c.CHART_ID = cdc.CHART_ID
INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID

SELECT cm.CPT_Code
  into #PPE_CPT
FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
	and ppe.CHART_ID = @chart_id	

select TOP 1 @PSP_CPT = CPT_CODE
FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
INNER JOIN #Chart c 
on PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
WHERE PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
        WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
            THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
        ELSE c.PHYSICIAN_SERVICE_PROC_ID
        END
-------------------------------------------------------------------------------------------------------------------

--RequiredMeasuresOldLogic
--AS (
SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		ROW_NUMBER() OVER (
			PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredMeasuresOldLogic	-- tuning, 2/21/2023 (dsexton)
	--FROM MeasureList ml
	from #MeasureList ml		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE (
			/*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
				
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR (cdc.DIAGNOSIS_TYPE_ID IN (1,3,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			OR (
				ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select 1 from #PPE_CPT as t where t.CPT_Code = ml.Code		-- tuning to replace old subquery, 2/21/2023 (dsexton)
					)
				)
			)
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
      ml.REQUIRES_EM_ONLY = 1
      AND 
			@PSP_CPT	 -- tuning to replace subquery, 2/21/2023 (dsexton)
			  IN ('99201','99202','99203','99204','99205','99212','99213','99214','99215','99281','99282','99283','99284','99285','99383','99384','99385','99393','99394','99395')
    )
--	)
-- select '#RequiredMeasuresOldLogic' = null
-- select * from #RequiredMeasuresOldLogic where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--,
--RequiredDiagnosisMeasures
--AS (

	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 		   
		  /*ml.CODING_SYSTEM = 'I9' -- DACS-3417, 08/19/2024 (pippin)
			AND EXISTS (
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 1)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 1)
								)
							)
						-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
						AND (
							NOT EXISTS (
								-- Trigger if no code exist for the measure 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								)
							OR EXISTS (
								-- Or if a the correct combination is found 
								SELECT *
								FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
								WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
									AND CODE_1 = cdc.ICD10_CODE
									AND CODE_2 IN (
										SELECT ICD10_CODE
										--FROM CHART_DIAGNOSIS_CODE_ICD10 WITH (NOLOCK)
										from #ChartDiagCodeICD10		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
										WHERE 
											(
                        ICD10_CODE <> cdc.ICD10_CODE
                        OR CODE_1 = CODE_2
                      )
										)
								)
							)
					)
				)
			

--    )
	  
-- select '#RequiredDiagnosisMeasures' = null
-- select * from #RequiredDiagnosisMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing
	
--	,
--	RequiredDiagnosisMeasures2
--AS (
	SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequiredDiagnosisMeasures2
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE 
		 /*  -- DACS-3417, 08/19/2024 (pippin)
		  ml.CODING_SYSTEM = 'I9'
			AND EXISTS (
			/-*	-- example of old subquery, 2/21/2023 (dsexton)
				SELECT *
				FROM CHART_DIAGNOSIS_CODE cdc WITH (NOLOCK)
				INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = cdc.CHART_ID
				INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
				WHERE cdc.CHART_ID = @chart_id
			*-/
				select * from #ChartDiagCode9 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
				where
					cdc.ICD9_CODE = ml.CODE
					AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					AND (
						ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
						OR (
							cdc.CHIEF_COMPLAINT = cdc.PRIMARY_COMPLAINT
							OR cdc.ICD9_CODE <> cdc.CHIEF_COMPLAINT
							)
						)
					-- 2-3-2015 DanielB: ACS-4219 - Handle measures that trigger on a combination of diagnosis codes
					AND (
						NOT EXISTS (
							-- Trigger if no code exist for the measure 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
							)
						OR EXISTS (
							-- Or if a the correct combination is found 
							SELECT *
							FROM CMS_PQRI_MEASURE_CODE_GROUP WITH (NOLOCK)
							WHERE CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
								AND CODE_1 = cdc.ICD9_CODE
								AND CODE_2 IN (
									SELECT ICD9_CODE
									--FROM CHART_DIAGNOSIS_CODE WITH (NOLOCK)
									from #ChartDiagCode9		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
									WHERE 
										(
                      ICD9_CODE <> cdc.ICD9_CODE
                      OR CODE_1 = CODE_2
                    )
									)
							)
						)
				)
			OR*/ (
				ml.CODING_SYSTEM IN ('I10','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					select * from #ChartDiagCodeICD10 as cdc		-- tuning with temp table in the subquery, 2/21/2023 (dsexton)
					where
						cdc.ICD10_CODE = ml.CODE
					    AND CONVERT(Date, cdc.TIME_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
						AND (
							ISNULL(INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND, 0) = 1
							OR (
								(cdc.DIAGNOSIS_TYPE_ID = 3 AND cdc.IS_PRIMARY = 0)
								OR NOT (cdc.DIAGNOSIS_TYPE_ID IN (1,5) AND cdc.IS_PRIMARY = 0)
								)
							)
						)
			
			)
 --   )
	  
-- select '#RequiredDiagnosisMeasures2' = null
-- select * from #RequiredDiagnosisMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	,
--	RequireCptMeasures
--AS (
     SELECT ml.CMS_PQRI_MEASURE_ID,
		ml.MEASURE_TITLE,
		ml.REQUIRES_BOTH_CPT_AND_DX,
		ml.CMS_PQRI_MEASURE_CODE_ID,
		ml.CODING_SYSTEM,
		ml.OPTION_GROUP,
		ml.CODE,
		ml.MODIFIER,
		ml.[DESCRIPTION],
		ml.END_DATE,
		ml.CODE_2,
		ml.MODIFIER_2,
		--ROW_NUMBER() OVER (
			--PARTITION BY CMS_PQRI_MEASURE_ID ORDER BY CODE DESC
			--) [ROW_NUMBER],
		REQUIRES_EM_ONLY,
		ml.DATE_OF_SERVICE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE,
		ml.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE,
		ml.REQUIRES_MULTIPLE_CPTS,
		ml.MULTIPLE_CPT_COUNT,
		ml.REQUIRES_MULTIPLE_DX,
		ml.REQUIRES_CPT_CODE,
		ml.REQUIRED_CPT_CODE,
		ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		ml.MEASURE_HOTSHEET_URI	-- DACS-3417, 08/19/2024 (pippin)
into #RequireCptMeasures
	--FROM MeasureList ml
	from #MeasureList ml			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	WHERE ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
				AND EXISTS (
					SELECT *
					FROM PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
					INNER JOIN CHARGE_MASTER cm WITH (NOLOCK) ON cm.CHARGE_MASTER_ID = ppe.PHYSICIAN_PROCEDURE_ID
					WHERE ppe.CHART_ID = @chart_id
						AND cm.CPT_CODE = ml.CODE
						AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
					)
				
			
			
			
			
		-- 1-30-2014 DanielB: ACS-4042 - REQUIRES_EM_ONLY indicates that the measure triggers by age, gender and E&M assigned only. No additional procedure/diagnosis is required.
		-- 9-1-2015 JohnS - Temporarily commented out check for REQUIRES_EM_ONLY to prevent PQRS #317 from triggering for now
		OR (
		ml.CODING_SYSTEM IN ('C4','DG1P1','DG1P2','DG2P1','DG2P2','DG2P3')
      AND  (
              SELECT  CPT_CODE
              FROM PHYSICIAN_SERVICE_PROCEDURE WITH (NOLOCK)
              INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = @chart_id
              WHERE PHYSICIAN_SERVICE_PROCEDURE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
                  AND PHYSICIAN_SERVICE_PROCEDURE.PHYSICIAN_SERVICE_PROC_ID = CASE 
                      WHEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID > 0
                          THEN c.OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
                      ELSE c.PHYSICIAN_SERVICE_PROC_ID
                      END 
              ) = ml.Code
			  AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
			  )
--),

-- select '#RequireCptMeasures' = null
-- select * from #RequireCptMeasures where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

--	RequiredMeasures2
--AS (
   
    SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
		rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
into #RequiredMeasures2
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		
		UNION
		SELECT rdm.CMS_PQRI_MEASURE_ID,
		rdm.MEASURE_TITLE,
		rdm.REQUIRES_BOTH_CPT_AND_DX,
		rdm.CMS_PQRI_MEASURE_CODE_ID,
		rdm.CODING_SYSTEM,
		rdm.OPTION_GROUP,
		rdm.CODE,
		rdm.MODIFIER,
        rdm.[DESCRIPTION],
		rdm.END_DATE,
		rdm.CODE_2,
		rdm.MODIFIER_2,
		rdm.REQUIRES_EM_ONLY,
		rdm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm.CMS_PQRI_MEASURE_ID ORDER BY rdm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures rdm
		from #RequiredDiagnosisMeasures rdm														-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS = 1
		AND rdm.REQUIRES_MULTIPLE_DX IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		GROUP BY rdm.CMS_PQRI_MEASURE_ID, rdm.MEASURE_TITLE, rdm.REQUIRES_BOTH_CPT_AND_DX, rdm.CMS_PQRI_MEASURE_CODE_ID, rdm.CODING_SYSTEM, rdm.OPTION_GROUP, rdm.CODE, rdm.MODIFIER, rdm.[DESCRIPTION], rdm.END_DATE, rdm.CODE_2, rdm.MODIFIER_2, rdm.REQUIRES_EM_ONLY, rdm.MEASURE_TOOLTIP, rdm.MEASURE_HOTSHEET_URI, rcm.MULTIPLE_CPT_COUNT
		HAVING COUNT(rcm.CODE) = rcm.MULTIPLE_CPT_COUNT

		UNION
		SELECT rdm2.CMS_PQRI_MEASURE_ID,
		rdm2.MEASURE_TITLE,
		rdm2.REQUIRES_BOTH_CPT_AND_DX,
		rdm2.CMS_PQRI_MEASURE_CODE_ID,
		rdm2.CODING_SYSTEM,
		rdm2.OPTION_GROUP,
		rdm2.CODE,
		rdm2.MODIFIER,
        rdm2.[DESCRIPTION],
		rdm2.END_DATE,
		rdm2.CODE_2,
		rdm2.MODIFIER_2,
		rdm2.REQUIRES_EM_ONLY,
		rdm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rdm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rdm2.CMS_PQRI_MEASURE_ID ORDER BY rdm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredDiagnosisMeasures2 rdm2
		from #RequiredDiagnosisMeasures2 rdm2															-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequireCptMeasures rcm ON rcm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID				-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--JOIN RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID
		join #RequiredDiagnosisMeasures rdm ON rdm.CMS_PQRI_MEASURE_ID = rdm2.CMS_PQRI_MEASURE_ID		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		
		WHERE rdm.REQUIRES_BOTH_CPT_AND_DX = 1
		AND rdm.REQUIRES_MULTIPLE_DX = 1
		AND rdm.REQUIRES_MULTIPLE_CPTS IS NULL
		AND CONVERT(Date, rdm.DATE_OF_SERVICE) BETWEEN rdm.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE AND rdm.REQUIRES_BOTH_CPT_AND_DX_EXP_DATE 
		AND rdm.CODE IS NOT NULL
		AND rcm.CODE IS NOT NULL
		AND rdm2.CODE IS NOT NULL
		UNION
		
		SELECT rmol.CMS_PQRI_MEASURE_ID,
		rmol.MEASURE_TITLE,
		rmol.REQUIRES_BOTH_CPT_AND_DX,
		rmol.CMS_PQRI_MEASURE_CODE_ID,
		rmol.CODING_SYSTEM,
		rmol.OPTION_GROUP,
		rmol.CODE,
		rmol.MODIFIER,
		rmol.[DESCRIPTION],
		rmol.END_DATE,
		rmol.CODE_2,
		rmol.MODIFIER_2,
		rmol.REQUIRES_EM_ONLY,
		rmol.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rmol.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rmol.CMS_PQRI_MEASURE_ID ORDER BY rmol.CODE DESC
			) [ROW_NUMBER]
		--FROM RequiredMeasuresOldLogic rmol
		from #RequiredMeasuresOldLogic rmol			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		WHERE rmol.REQUIRES_BOTH_CPT_AND_DX = 1
		AND CONVERT(Date, rmol.DATE_OF_SERVICE) < rmol.REQUIRES_BOTH_CPT_AND_DX_EFF_DATE
		AND rmol.CODE IS NOT NULL
		
		
		UNION
		 
		SELECT rcm.CMS_PQRI_MEASURE_ID,
		rcm.MEASURE_TITLE,
		rcm.REQUIRES_BOTH_CPT_AND_DX,
		rcm.CMS_PQRI_MEASURE_CODE_ID,
		rcm.CODING_SYSTEM,
		rcm.OPTION_GROUP,
		rcm.CODE,
		rcm.MODIFIER,
		rcm.[DESCRIPTION],
		rcm.END_DATE,
		rcm.CODE_2,
		rcm.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm.CMS_PQRI_MEASURE_ID ORDER BY rcm.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm
		from #RequireCptMeasures rcm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND COALESCE(rcm.REQUIRES_CPT_CODE, 0) = 0
		AND rcm.CODE IS NOT NULL

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 185) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		 

		 UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		REQUIRES_EM_ONLY,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 184) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		UNION
		 
		SELECT rcm2.CMS_PQRI_MEASURE_ID,
		rcm2.MEASURE_TITLE,
		rcm2.REQUIRES_BOTH_CPT_AND_DX,
		rcm2.CMS_PQRI_MEASURE_CODE_ID,
		rcm2.CODING_SYSTEM,
		rcm2.OPTION_GROUP,
		rcm2.CODE,
		rcm2.MODIFIER,
		rcm2.[DESCRIPTION],
		rcm2.END_DATE,
		rcm2.CODE_2,
		rcm2.MODIFIER_2,
		rcm2.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
		rcm2.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
		REQUIRES_EM_ONLY,
		ROW_NUMBER() OVER (
			PARTITION BY rcm2.CMS_PQRI_MEASURE_ID ORDER BY rcm2.CODE DESC
			) [ROW_NUMBER]
		--FROM RequireCptMeasures rcm2
		from #RequireCptMeasures rcm2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)

		WHERE COALESCE(rcm2.REQUIRES_BOTH_CPT_AND_DX, 0) = 0
		AND rcm2.REQUIRES_CPT_CODE = 1
		AND rcm2.CODE IS NOT NULL
		--AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)
		AND rcm2.REQUIRED_CPT_CODE IN(SELECT CODE FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189)		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
		--AND (SELECT COUNT(CODE) FROM RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1
		AND (SELECT COUNT(CODE) FROM #RequireCptMeasures WHERE CMS_PQRI_MEASURE_ID = 189) > 1					-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--)

-- select '#RequiredMeasures2' = null
-- select * from #RequiredMeasures2 where measure_title like '%332%' OR measure_title like '% 7-%' -- testing

	
SELECT DISTINCT CMS_PQRI_MEASURE_ID,
	MEASURE_TITLE,
	CMS_PQRI_MEASURE_CODE_ID,
	CODING_SYSTEM,
	NULL OPTION_GROUP,
	CASE COALESCE(REQUIRES_EM_ONLY, 0)
		WHEN 1
			THEN 'E&M'
		ELSE CODE
		END CODE,
	NULL MODIFIER,
	NULL [DESCRIPTION],
	NULL END_DATE,
	NULL CODE_2,
	NULL MODIFIER_2,
	NULL MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	NULL MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	CAST([ROW_NUMBER] AS BIGINT) [ROW_NUMBER]
--FROM RequiredMeasures2
from #RequiredMeasures2		-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
WHERE @measure_id IS NULL
	AND @measure_code_id IS NULL
	AND [ROW_NUMBER] = 1

UNION

SELECT ml.CMS_PQRI_MEASURE_ID,
	ml.MEASURE_TITLE,
	ml.CMS_PQRI_MEASURE_CODE_ID,
	ml.CODING_SYSTEM,
	ml.OPTION_GROUP,
	ml.CODE,
	ml.MODIFIER,
	ml.[DESCRIPTION],
	ml.END_DATE,
	ml.CODE_2,
	ml.MODIFIER_2,
	ml.MEASURE_TOOLTIP,	-- DACS-3417, 08/19/2024 (pippin)
	ml.MEASURE_HOTSHEET_URI,	-- DACS-3417, 08/19/2024 (pippin)
	NULL [ROW_NUMBER]
--FROM MeasureList ml
from #MeasureList ml						-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
--INNER JOIN RequiredMeasures2 rm ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
INNER JOIN #RequiredMeasures2 rm			-- tuning with temp table that replaces CLR query, 2/21/2023 (dsexton)
	ON rm.CMS_PQRI_MEASURE_ID = ml.CMS_PQRI_MEASURE_ID
WHERE (
		ml.CMS_PQRI_MEASURE_ID = @measure_id
		OR ml.CMS_PQRI_MEASURE_CODE_ID = @measure_code_id
		)
	AND ml.CODING_SYSTEM IN (
		'CPT_II',
		'HCPCS'
		)
	AND CONVERT(Date, ml.DATE_OF_SERVICE) BETWEEN ml.START_DATE AND ml.END_DATE
	
ORDER BY CMS_PQRI_MEASURE_ID ASC,
	MEASURE_TITLE DESC

GO

IF NOT EXISTS (SELECT * FROM sys.fn_listextendedproperty(N'MS_Description' , N'SCHEMA',N'dbo', N'PROCEDURE',N'spSelectChartPqrs', N'PARAMETER',N'@MeasureCodeId'))
	EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
ELSE
BEGIN
	EXEC sys.sp_updateextendedproperty @name=N'MS_Description', @value=N'When null, return the required PQRS measures. Otherwise return measure code options associated with the CMS_PQRI_MEASURE_ID.' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'PROCEDURE',@level1name=N'spSelectChartPqrs', @level2type=N'PARAMETER',@level2name=N'@MeasureCodeId'
END

GO


