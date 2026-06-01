------------------------------------------------------------------------------------
-- 01) DACS-3536 - Script - CMS_PQRI_MEASURE_CODE - update [DESCRIPTION] column to correct to HTML conversion errors.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO
-- begin tran; -- testing

--------------------------------------
-- backup table before we work on it
--------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3536b';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3536b';

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


--------------------------------------
--  adjust: '%(LVEF) = 40%'
--------------------------------------
DECLARE @CountItemsToProcess INT = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] LIKE '%(LVEF) = 40%'
	) ;

SELECT '# to process (expect ~3)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = replace([DESCRIPTION], '(LVEF) = 40', '(LVEF) less than or equal to 40')
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] LIKE '%(LVEF) = 40%'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] LIKE '%(LVEF) = 40%'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess
	
--------------------------------------
--  adjust: '%LVEF = 40%' in measures table
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE]
	WHERE 
		[MEASURE_TITLE] LIKE '%LVEF = 40%'
	) ;

SELECT '# to process (expect ~4)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = REPLACE([MEASURE_TITLE], 'LVEF = 40', 'LVEF less than or equal to 40')
WHERE 
	[MEASURE_TITLE] LIKE '%LVEF = 40%'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE]
	WHERE 
		[MEASURE_TITLE] LIKE '%LVEF = 40%'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess
		
	
--------------------------------------
--  adjust: 'Does patient have Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Does patient have Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = 'Does patient have Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Does patient have Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess
	
--------------------------------------
--  adjust: 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function?'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function?'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function: M1150?'
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function?'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderately or severely depressed left ventricular systolic function?'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess
	
--------------------------------------
--  adjust: '=210 minutes'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (= 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (= 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (= 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess


--------------------------------------
--  adjust: '(= 270 minutes)'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] LIKE '%(= 270 minutes)%'
	) ;

SELECT '# to process (expect ~3)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = replace([DESCRIPTION], '(= 270 minutes)', '(less than or equal to 270 minutes)')
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] LIKE '%(= 270 minutes)%'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] LIKE '%(= 270 minutes)%'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess


--------------------------------------
--  adjust: '(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy?'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = '(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy?'
		AND [CODE] = 'G9595'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = '(DENOMINATOR EXCLUSION): Patient has documentation of ventricular shunt, brain tumor, or coagulopathy?'
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = '(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy?'
	AND [CODE] = 'G9595'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = '(DENOMINATOR EXCLUSION): Patient was NOT documentated with ventricular shunt, brain tumor, or coagulopathy?'
		AND [CODE] = 'G9595'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess

--------------------------------------
--  adjust: [CODE] = 'G9597'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Performance Not Met: Pediatric patient with minor blunt head trauma not classified as low risk according to the PECARN prediction rules. <p><img src="/WebPages/Images/MIPS/MIPS416_PECARN_definition.png" alt="(G9597) PECARN prediction rules image"></p> '
		AND [CODE] = 'G9597'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Performance Not Met: Pediatric patient with minor blunt head trauma not classified as low risk according to the PECARN prediction rules. (G9597) <p><img src="/WebPages/Images/MIPS/MIPS416_PECARN_definition.png" alt="(G9597) PECARN prediction rules image"></p> '
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = 'Performance Not Met: Pediatric patient with minor blunt head trauma not classified as low risk according to the PECARN prediction rules. <p><img src="/WebPages/Images/MIPS/MIPS416_PECARN_definition.png" alt="(G9597) PECARN prediction rules image"></p> '
	AND [CODE] = 'G9597'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Performance Not Met: Pediatric patient with minor blunt head trauma not classified as low risk according to the PECARN prediction rules. <p><img src="/WebPages/Images/MIPS/MIPS416_PECARN_definition.png" alt="(G9597) PECARN prediction rules image"></p> '
		AND [CODE] = 'G9597'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess


--------------------------------------
--  adjust: [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
		AND [CODE] = '00001'
	) ;

SELECT '# to process (expect ~1)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Was <strong>time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes):</strong> (“Pseudo” code) - <strong>PAR2Y</strong>? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p> '
		,[CODE] = 'PAR2Y'
WHERE
	([START_DATE] IS NULL OR [START_DATE] < GETDATE())
	AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
	AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
	AND [CODE] = '00001'
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND [DESCRIPTION] = 'Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>'
		AND [CODE] = '00001'
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess

--------------------------------------
--  adjust: measure titles as directed by L Renegar
--------------------------------------
SELECT 'adjust: measure titles as directed by L Renegar'

UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = 'MIPS# 118-A : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF CAD WITH LVEF less than or equal to 40% (WITHOUT A DIAGNOSIS OF DIABETES)) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB therapy.'
WHERE
	CMS_PQRI_MEASURE_ID = 199;
		
UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = 'MIPS# 118-B : Coronary Artery Disease (CAD): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) Therapy - Diabetes or Left Ventricular Systolic Dysfunction (LVEF less than or equal to 40%) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF CAD WHO HAVE DIABETES) : Percentage of patients aged 18 years and older with a diagnosis of coronary artery disease seen within a 12-month period who also have diabetes OR a current or prior Left Ventricular Ejection Fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB therapy.'
WHERE
	CMS_PQRI_MEASURE_ID = 200;

UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = 'MIPS# 005-A : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 1: ALL PATIENTS WITH A DIAGNOSIS OF HF ASSESSED DURING AN OUTPATIENT ENCOUNTER): Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.'
WHERE
	CMS_PQRI_MEASURE_ID = 202;

UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = 'MIPS# 005-B : Heart Failure (HF): Angiotensin-Converting Enzyme (ACE) Inhibitor or Angiotensin Receptor Blocker (ARB) or Angiotensin Receptor-Neprilysin Inhibitor (ARNI) Therapy for Left Ventricular Systolic Dysfunction (LVSD) : (SUBMISSION CRITERIA 2: ALL PATIENTS WITH A DIAGNOSIS OF HF AND DISCHARGED FROM HOSPITAL DENOMINATOR) : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed ACE inhibitor or ARB or ARNI therapy either within a 12-month period when seen in the outpatient setting OR at each hospital discharge.'
WHERE
	CMS_PQRI_MEASURE_ID = 203;

UPDATE [CMS_PQRI_MEASURE]
	SET [MEASURE_TITLE] = 'THEPQR3 : SGLT-2 inhibitors for patients with HFrEF with or without Type 2 Diabetes : Percentage of patients aged 18 years and older with a diagnosis of heart failure (HF) with a current or prior left ventricular ejection fraction (LVEF) less than or equal to 40% who were prescribed SGLT-2 Inhibitors with or without Type 2 diabetes during their SNF stay or discharge from either the hospital (inpatient or observation) or SNF.'
WHERE
	CMS_PQRI_MEASURE_ID = 221;
		
SELECT * FROM [CMS_PQRI_MEASURE] WHERE CMS_PQRI_MEASURE_ID IN (199,200,202,203,221);

--------------------------------------
--  adjust: measure titles as directed by L Renegar
--------------------------------------
SELECT 'adjust: measure code descriptions as directed by L Renegar'

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderate or severe LVSD: G8694? '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 7524;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Is Left ventricular ejection fraction (LVEF) less than or equal to 40% or documentation of moderate or severe LVSD: G8694? '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 15442;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Denominator Exception: Beta-Blocker Therapy for LVEF less than or equal to 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload, asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons) <p><img src="/WebPages/Images/MIPS/MIPS_008_Table1.png" alt="(G8451) Exception table image"></p> '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 10638;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Denominator Exception: Beta-Blocker Therapy for LVEF less than or equal to 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload  , asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons) <p><img src="/WebPages/Images/MIPS/MIPS_008_Table1.png" alt="(G8451) Exception table image"></p> '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 10669;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Denominator Exception: Beta-Blocker Therapy for LVEF less than or equal to 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload, asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons) '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 5585;

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [DESCRIPTION] = 'Denominator Exception: Beta-Blocker Therapy for LVEF less than or equal to 40% not prescribed for reasons documented by the clinician (e.g., low blood pressure, fluid overload, asthma, patients recently treated with an intravenous positive inotropic agent, allergy, intolerance, other medical reasons, patient declined, other patient reasons) '
WHERE
	CMS_PQRI_MEASURE_CODE_ID = 5614;

SELECT * FROM [CMS_PQRI_MEASURE_CODE] WHERE CMS_PQRI_MEASURE_CODE_ID IN (7524,15442,10638,10669,5585,5614);


GO

/*
testing:
-- rollback tran; -- testing
-- commit tran; -- testing

select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332'
select top 200 * from CMS_PQRI_MEASURE_CODE where ???

SELECT *
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([START_DATE] IS NULL OR [START_DATE] < GETDATE())
		AND ([END_DATE] IS NULL OR [END_DATE] > GETDATE())
		AND ([DESCRIPTION] LIKE '%(LVEF) = 40%'
			OR [DESCRIPTION] LIKE '%(LVEF) less than or equal to 40%'
			OR [DESCRIPTION] LIKE '%210%'
			OR [DESCRIPTION] LIKE '%270%'
			OR [DESCRIPTION] LIKE '%Was time last known well to hospital arrival less than or equal to 3.5 hours (less than or equal to 210 minutes)? <p><strong>Definition:</strong></p><p><strong>Last Known Well –</strong> The date and time prior to hospital arrival at which it was witnessed or reported that the patient was last known to be without the signs and symptoms of the current stroke or at his or her baseline state of health.</p>%'
			)
		OR ([CODE] = 'G9595')
		OR ([CODE] = 'G9597')


*/