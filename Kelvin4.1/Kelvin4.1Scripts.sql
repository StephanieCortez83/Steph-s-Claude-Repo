USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3536 - Script - CMS_PQRI_MEASURE_CODE - update [DESCRIPTION] column to correct to HTML conversion errors.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3536 - Script - CMS_PQRI_MEASURE_CODE - update [DESCRIPTION] column to correct to HTML conversion errors.SQL
------------------------------------------------------------------------------------
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
-- End of 01) DACS-3536 - Script - CMS_PQRI_MEASURE_CODE - update [DESCRIPTION] column to correct to HTML conversion errors.SQL
GO

-- Start of 02) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 332.SQL

------------------------------------------------------------------------------------
-- 02) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 332.SQL
------------------------------------------------------------------------------------
GO
--begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '332';
	DECLARE @Dos DATETIME = '01-01-2024'

	DECLARE @countPQRS INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	print('@countPQRS = ' + CAST(@countPQRS AS VARCHAR(20)));

	IF @countPQRS > 0
	BEGIN 
		PRINT('!!!!! Updating...');

		UPDATE [dbo].[CMS_PQRI_MEASURE]
			SET  [REQ_2_DX_OR_3CPT] = 1
				,[PQRS#] = @PqrsCd
				,[MEASURE_TOPIC] = 'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,[MEASURE_TITLE] = 'MIPS# ' + @PqrsCd + ' :  Adult Sinusitis: Appropriate Choice of Antibiotic: Amoxicillin With or Without Clavulanate Prescribed for Patients with Acute Bacterial Sinusitis (Appropriate Use) : Percentage of patients aged 18 years and older with a diagnosis of acute bacterial sinusitis that were prescribed amoxicillin, with or without clavulanate, as a first line antibiotic at the time of diagnosis. '
				,[EFFECTIVE_DATE] = @Dos
				,[EXPIRATION_DATE] = NULL
		WHERE [PQRS#] = @PqrsCd
			AND [EFFECTIVE_DATE] <= @Dos
			AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos);	
	END
	ELSE 
	BEGIN
		PRINT('Inserting...');
		
		INSERT INTO [dbo].[CMS_PQRI_MEASURE]
			(
				 [PQRS#]
				,[MEASURE_TOPIC]
				,[MEASURE_TITLE]
				,[GENDER]
				,[FROM_AGE]
				,[TO_AGE]
				,[EFFECTIVE_DATE]
				,[EXPIRATION_DATE]
				,[REQUIRES_EM_ONLY]
				,[FROM_AGE_FRACTIONAL]
				,[TO_AGE_FRACTIONAL]
				,[MATCH_EM_LEVEL]
				,[REQUIRES_BOTH_CPT_AND_DX]
				,[REQUIRES_BOTH_CPT_AND_DX_EFF_DATE]
				,[REQUIRES_BOTH_CPT_AND_DX_EXP_DATE]
				,[REQUIRES_MULTIPLE_CPTS]
				,[MULTIPLE_CPT_COUNT]
				,[REQUIRES_MULTIPLE_DX]
				,[REQUIRES_CPT_CODE]
				,[REQUIRED_CPT_CODE]
				,[REQ_2_DX_OR_3CPT]
			)
		VALUES
			(
				 @PqrsCd
				,'MIPS CLINICAL QUALITY MEASURES (CQMS)'
				,'MIPS# ' + @PqrsCd + ' :  Adult Sinusitis: Appropriate Choice of Antibiotic: Amoxicillin With or Without Clavulanate Prescribed for Patients with Acute Bacterial Sinusitis (Appropriate Use) : Percentage of patients aged 18 years and older with a diagnosis of acute bacterial sinusitis that were prescribed amoxicillin, with or without clavulanate, as a first line antibiotic at the time of diagnosis. '
				,'B'
				,18
				,999
				,'2024-01-01'
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,NULL
				,1
			);
	END;

	DECLARE @countPQRSFinal INT = 
		(
			SELECT COUNT(*) 
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
				AND [REQ_2_DX_OR_3CPT] = 1
		);

	SELECT 'Result' = @countPQRSFinal;

-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332' -- = 170
*/
-- End of 02) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE] - MIPS# = 332.SQL
GO

-- Start of 03) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL

------------------------------------------------------------------------------------
-- 03) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL
------------------------------------------------------------------------------------
GO

-- begin tran; -- testing
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @PqrsCd VARCHAR(20) = '332';
	DECLARE @Dos DATETIME = '01-01-2024';

	DECLARE @MeasureId INT = 
		(
			SELECT [CMS_PQRI_MEASURE_ID]
			FROM [dbo].[CMS_PQRI_MEASURE] 
			WHERE [PQRS#] = @PqrsCd
				AND [EFFECTIVE_DATE] <= @Dos
				AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )	
		);

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN 
		PRINT('No Measure loaded for ' + @PqrsCd + '.  Cannot continue.');
		SELECT 'Error' = -1;
		RETURN;
	END;

	PRINT('@MeasureId = ' + CAST(@MeasureId AS VARCHAR(30)));

	DECLARE @countPQRSCodes INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodes' = @countPQRSCodes; -- testing


	IF @countPQRSCodes > 0
	BEGIN 
		PRINT('Found Measure Codes.  Expiring existing.');
	
		UPDATE [CMS_PQRI_MEASURE_CODE]
			SET [END_DATE] = DATEADD(minute,-1,CAST(CAST(@Dos AS DATE) AS DATETIME))
		WHERE
			[CMS_PQRI_MEASURE_ID] = @MeasureId
			AND [START_DATE] <= @Dos
			AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
			AND [CODE] IS NOT NULL
			AND [CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	END;

	DECLARE @countPQRSCodesAfterExpiration INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesAfterExpiration' = @countPQRSCodesAfterExpiration; -- testing

	IF @countPQRSCodesAfterExpiration > 0
	BEGIN 
		PRINT('ERROR: Found Measure Codes AFTER EXPIRATION.  Exiting.');
		RETURN;
	END;


	INSERT INTO [CMS_PQRI_MEASURE_CODE] ([CMS_PQRI_MEASURE_ID],[CODING_SYSTEM],[CODE],[MODIFIER],[START_DATE],[DESCRIPTION])
	VALUES
		-- Diagnosis for acute sinusitis (ICD-10-CM):
		 (@MeasureId,'DG1P1','J01.00',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.01',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.10',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.11',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.30',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.31',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.40',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.41',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.80',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.90',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P1','J01.91',NULL,@Dos,NULL)
	
		-- Patient encounter during the performance period (CPT)
		,(@MeasureId,'DG1P2','99202',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99203',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99204',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99205',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99212',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99213',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99214',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99215',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99281',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99282',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99283',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99284',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99285',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99304',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99305',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99306',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99307',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99308',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99309',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99310',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99341',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99342',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99344',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99345',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99347',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99348',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99349',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99350',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99424',NULL,@Dos,NULL)
		,(@MeasureId,'DG1P2','99491',NULL,@Dos,NULL)

		-- Diagnosis for bacterial and infectious agents (ICD-10-CM)
		,(@MeasureId,'DG2P1','B95.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.2',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.61',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.62',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B95.8',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.0',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.1',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.20',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.21',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.22',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.23',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.29',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.3',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.4',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.5',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.6',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.7',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.81',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.82',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.83',NULL,@Dos,NULL)
		,(@MeasureId,'DG2P1','B96.89',NULL,@Dos,NULL)
		
		-- measure code numerators
		,(@MeasureId,'HCPCS','G9315',NULL,@Dos,'Performance Met: Amoxicillin, with or without clavulanate, prescribed asa first line antibiotic at the time of diagnosis. ')
		,(@MeasureId,'HCPCS','G9314',NULL,@Dos,'Performance Not Met: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis, reason not given. ')
		,(@MeasureId,'HCPCS','G9313',NULL,@Dos,'Denominator Exception: Amoxicillin, with or without clavulanate, not prescribed as first line antibiotic at the time of diagnosis for documented reason. ')
				
		-- PQRS Question for response by coder within ACS		
		,(@MeasureId,'DQ411','G9364',NULL,@Dos,'Sinusitis caused by, or presumed to be caused by, bacterial infection: G9364? ')
		,(@MeasureId,'DQ411','G9498',NULL,@Dos,'Antibiotic regimen prescribed: G9498?')
		
		,(@MeasureId,'OTHER','99999',NULL,@Dos,'Measure not met for other reasons')
		
		; -- expect 35 total inserts
		
		
	DECLARE @countPQRSCodesFinal INT = 
		(
			SELECT COUNT(*) 
			FROM 
				[CMS_PQRI_MEASURE_CODE] cpmc
				INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
			WHERE
				cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
				AND cpmc.[START_DATE] <= @Dos
				AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
				AND cpm.[EFFECTIVE_DATE] <= @Dos
				AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
				AND cpmc.[CODE] IS NOT NULL
				AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
		);

	SELECT '@countPQRSCodesFinal' = @countPQRSCodesFinal;

	-- testing:
	SELECT 
		*
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND cpmc.[CODE] IS NOT NULL
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1','DG2P2','DG2P3','HCPCS','DQ411','OTHER')
	ORDER BY
		CMS_PQRI_MEASURE_CODE_ID;
		
-- rollback tran; -- testing
-- commit tran; -- testing

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '332' -- = 170
select top 2000 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 170
--begin tran
--delete from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 170
--commit tran;
*/
-- End of 03) DACS-3536 - Script - Modify [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] - add codes for new processing method = 332.SQL
GO

-- Start of 04) DACS-3536 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL

------------------------------------------------------------------------------------
-- 04) DACS-3536 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;

		SET @patientAge = dbo.fGetPatientAgeInYears(@patientAge,@chartDos,(SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo))

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 

	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing


	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;
	
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	IF @foundDenominatorQuestionsMatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		RETURN;
	END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for acute sinusitis (ICD-10-CM)?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for acute sinusitis (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;
	
	-- do we have a Diagnosis for bacterial and infectious agents (ICD-10-CM)?
	DECLARE @AskQuestionG9364 VARCHAR(5) = 'G9364';
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		--SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for bacterial and infectious agents (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		SET @AskQuestionG9364 = 'GGGGG';
		PRINT('ask all questions since criteria Diagnosis for bacterial and infectious agents (ICD-10-CM) NOT found');
		--RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------
	
	SELECT TOP 5
		'411' AS 'RESULT' 
		, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
		, tdl.[CODE] AS 'CODE'
	FROM 
		#tempDenominatorList tdl
	WHERE 
		tdl.[CODING_SYSTEM] = 'DQ411'
		AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		AND tdl.[CODE] <> @AskQuestionG9364
	ORDER BY
		tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-A' -- = 210
begin tran; -- testing

exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332
	@ChartId = 2100113566
	,@PqrsNum = '332'
	--,@ShowDebug = 1
*/
-- End of 04) DACS-3536 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type332].SQL
GO

-- Start of 01) DACS-3550 - Script to expire specified records from table [CMS_PQRI_MEASURE_CODE].sql

----------------------------------------------------------------------
-- 01) DACS-3550 - Script to expire specified records from table [CMS_PQRI_MEASURE_CODE].sql
----------------------------------------------------------------------
/*
	expire all records from [CMS_PQRI_MEASURE_CODE] that are like the following:  
	"Is there at least one additional patient encounter during performance period (CPT)?" 
	and are "new 2024 MIPS" records.  (measure id >= 175)
*/

-- USE [CMSRules]; -- can use either in this instance.  Using the RevCycleDB to make things just a little less confusing during deployment
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Dos DATETIME = '01-01-2024';
DECLARE @ExpirationDate DATETIME = '01-01-2024';

	--------------------------------------------
	-- Backup our data to be worked upon
	--------------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3550';


	--------------------------------------------
	-- see what we are working on
	--------------------------------------------
DECLARE @CountToProcess INT = (
	SELECT 
		COUNT(*)
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] >= 175
		AND [START_DATE] <= @Dos
		AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
		AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	);

SELECT 'Count before Measure Code Processing (expect ~6) =' = @CountToProcess;


	--------------------------------------------
	-- update table 
	--------------------------------------------
UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
WHERE 
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%';


	--------------------------------------------
	-- double check
	--------------------------------------------
SET @CountToProcess = (
	SELECT 
		COUNT(*)
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		[CMS_PQRI_MEASURE_ID] >= 175
		AND [START_DATE] <= @Dos
		AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
		AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	);

SELECT 'Count after Measure Code Processing (expect ~0) =' = @CountToProcess;


GO

/*
begin tran;

DECLARE @Dos DATETIME = '01-01-2024';
DECLARE @ExpirationDate DATETIME = '01-01-2024';

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = NULL
WHERE 
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] = @ExpirationDate)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%';

-- rollback tran;
-- commit tran;

Tools:
select top 300 * from cms_pqri_measure order by cms_pqri_measure_id;
select top 300 * from cms_pqri_measure where cms_pqri_measure_id in (215,202,199,200,210,211);
select top 100 * from cms_pqri_measure_code where [description] like '%encounter%';

SELECT * 
FROM 
	[CMS_PQRI_MEASURE_CODE]
WHERE
	[CMS_PQRI_MEASURE_ID] >= 175
	AND [START_DATE] <= @Dos
	AND ([END_DATE] IS NULL OR [END_DATE] > @Dos)
	AND [DESCRIPTION] like '%one additional patient encounter during performance period%'
	
*/

-- End of 01) DACS-3550 - Script to expire specified records from table [CMS_PQRI_MEASURE_CODE].sql
GO

-- Start of 02) DACS-3550 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3550 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B] 
	  @ChartId INT
	, @MeasureId INT = NULL
	, @PqrsNum VARCHAR(20) = NULL
	, @Dos DATETIME = NULL
	, @ShowDebug BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	-- must be handled as 2 seperate SPROCS since the rules are so CLOSE

	-- Hat tip to dsexton.  Have stolen scripts lavishly througout

	-- in the case of MIPS 007, there are 2 valid decision paths.  the data is stored by PQRS# '007-A' and '007-B' for example.  This script is designed around this example.
	-- Other MIPS/PQRS Rules may use this same SPROC in time.  Will handle them seperately based on the MeasureId passed into this script
	
	-- returns 411 on Satisfaction of Rule such that the coder must respond to the question returned to finish up the PQRS / MIPS process within ACS

	-- returns 0 on NOT satisfing Rule - Column name will be 'Result' (Perfromance Not Met)
	-- returns -# for errors - Column name will be 'Error'.  This column title represents anything that did not allow for an actual satisfaction check of the CMS rule
	-- -1 = parameter errors
	-- -2 = age errors
	-- -3 = PQRS Measure Code errors

	----------------
	-- validate parameters
	----------------
	IF @ChartId IS NULL OR @ChartId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @ChartId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		IF @PqrsNum IS NOT NULL AND LEN(@PqrsNum) > 0
		BEGIN 
			DECLARE @testPqrs INT = (SELECT TOP 1 [CMS_PQRI_MEASURE_ID] FROM [dbo].[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EFFECTIVE_DATE] <= @Dos AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos ) )

			IF @testPqrs IS NOT NULL AND @testPqrs > 0
			BEGIN
				SET @MeasureId = @testPqrs;
				PRINT('@MeasureId set to ' + CAST(@MeasureId AS VARCHAR(40)));
			END;
		END;
	END;

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- Fill some temp tables
	IF OBJECT_ID('tempdb..#tempChartInfo') IS NOT NULL DROP Table #tempChartInfo
	IF OBJECT_ID('tempdb..#tempMeasureInfo') IS NOT NULL DROP Table #tempMeasureInfo
	IF OBJECT_ID('tempdb..#tempProcedureList') IS NOT NULL DROP Table #tempProcedureList
	IF OBJECT_ID('tempdb..#tempDiagnosisList') IS NOT NULL DROP Table #tempDiagnosisList
	IF OBJECT_ID('tempdb..#tempDenominatorList') IS NOT NULL DROP Table #tempDenominatorList

	----------------
	-- Chart info
	----------------
	SELECT 
		  CHART_ID
		, SERVICE_AGREEMENT_ID
		, PRIMARY_COMPLAINT
		, CHIEF_COMPLAINT
		, PHYSICIAN_SERVICE_PROC_ID
		, OVERRIDE_PHYSICIAN_SERVICE_PROC_ID
		, TIME_OF_SERVICE
		, GENDER
		, PATIENT_DOB
		, PATIENT_AGE
		, USE_TELEHEALTH
	INTO 
		#tempChartInfo	
	FROM 
		CHART
	WHERE 
		CHART_ID = @ChartId;

	IF @ShowDebug <> 0 SELECT * FROM #tempChartInfo; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempChartInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@ChartId returned no data.', 'Code' = 'ERR-0-NCD';
		RETURN;
	END;	
	
	----------------
	-- Measure info
	----------------
	SELECT TOP 1 
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#] 
		--, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [REQ_2_DX_OR_3CPT] 
	INTO 
		#tempMeasureInfo 
	FROM 
		[dbo].[CMS_PQRI_MEASURE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND [EFFECTIVE_DATE] <= @Dos
		AND	([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @Dos )
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC;
	
	IF @ShowDebug <> 0 SELECT * FROM #tempMeasureInfo; -- testing
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId returned no data', 'Code' = 'ERR-0-NMD';
		RETURN;
	END;
	
	IF (NOT EXISTS (SELECT 1 FROM #tempMeasureInfo WHERE [REQ_2_DX_OR_3CPT] = 1))
	BEGIN
		SELECT 'Error' = 0, 'Message' = '@MeasureId does not support this test', 'Code' = 'ERR-0-NMS';
		RETURN;
	END;
	 

	----------------
	-- check for gender CONSTRAINTS
	----------------
	-- No gender restrictions at this time.
	-- PRINT ('Gender criteria satisfied to continue comparisons.');	
	
	
	----------------
	-- check for age CONSTRAINTS ex Patients aged ≥ 18 years on date of encounter
	----------------
	DECLARE @ageFrom INT = (SELECT TOP 1 [FROM_AGE] from #tempMeasureInfo);
	DECLARE @ageTo INT = (SELECT TOP 1 [TO_AGE] from #tempMeasureInfo);
	
	IF @ageFrom IS NOT NULL OR @ageTo IS NOT NULL
	BEGIN
		-- collect patient date information
		DECLARE @patientAge INT = (SELECT TOP 1 [PATIENT_AGE] from #tempChartInfo);
		DECLARE @chartDos DATETIME = (SELECT TOP 1 [TIME_OF_SERVICE] from #tempChartInfo);

		IF @chartDos IS NULL
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid Date of Service to test';
			RETURN;
		END;
		
		IF @patientAge IS NULL
		BEGIN
			DECLARE @patienDOB DATETIME = (SELECT TOP 1 [PATIENT_DOB] from #tempChartInfo);
			
			IF @patienDOB IS NULL
			BEGIN 
				SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
				RETURN;
			END;
			
			SET @patientAge = ((CAST(@chartDos AS INT) - CAST(@patienDOB AS INT)) / 365.25) ;
		END;
		
		IF @patientAge < 0 OR @patientAge > 999
		BEGIN 
			SELECT 'Error' = -2, 'Message' = '@ChartId does not have a valid age or DOB to test';
			RETURN;
		END;

		-- check the age constraints
		IF @ageFrom IS NULL SET @ageFrom = 0;
		IF @ageTo IS NULL SET @ageTo = 999;
		
		IF @patientAge < @ageFrom OR @patientAge > @ageTo
		BEGIN 
			SELECT 'Result' = 0, 'Message' = '@ChartId does not fall within age test', 'Code' = 'ERR-0-AGE';
			RETURN;
		END;
	END;

	
	----------------
	-- Present Procedure List 
	----------------
	SELECT 
		  cm.[CPT_CODE],
		  ppe.[MODIFIERS]
	INTO 
		#tempProcedureList
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE]
		INNER JOIN #tempChartInfo c ON [PHYSICIAN_SERVICE_PROCEDURE].[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE [PHYSICIAN_SERVICE_PROCEDURE].[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO #tempProcedureList ([CPT_CODE])	VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) > 0 
		INSERT INTO #tempProcedureList ([MODIFIERS]) VALUES (@PSP_MODIFIERS);
	 
	IF @ShowDebug <> 0 SELECT * FROM #tempProcedureList; -- testing
	 

	----------------
	-- Present Diagnosis List 
	----------------
	SELECT 
		  cdc.ICD10_CODE
		, sa.INCLUDE_CHIEF_COMPLAINT_IN_PQRS_EVAL_IND
		, cdc.DIAGNOSIS_TYPE_ID
		, cdc.IS_PRIMARY
		, c.Time_of_Service
	INTO 
		#tempDiagnosisList
	FROM 
		CHART_DIAGNOSIS_CODE_ICD10 cdc
		INNER JOIN #tempChartInfo c ON c.CHART_ID = cdc.CHART_ID
		INNER JOIN SERVICE_AGREEMENT sa ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID;

	IF @ShowDebug <> 0 SELECT * FROM #tempDiagnosisList; -- testing


	IF (NOT EXISTS (SELECT 1 FROM #tempDiagnosisList) AND NOT EXISTS (SELECT 1 FROM #tempProcedureList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Diagnosis Codes nor Procedure codes', 'Code' = 'ERR-0-NDP';
		RETURN;
	END;


	----------------
	-- Test denominator constraints
	----------------
	SELECT 
		  [CODE]
		, [CODING_SYSTEM]
		, [DESCRIPTION]
		, [MODIFIER]
	INTO 
		#tempDenominatorList
	FROM 
		[CMS_PQRI_MEASURE_CODE] cpmc
		INNER JOIN [CMS_PQRI_MEASURE] cpm ON cpm.[CMS_PQRI_MEASURE_ID] = cpmc.[CMS_PQRI_MEASURE_ID]
	WHERE
		--cpm.[PQRS#] = @cmpCd
		cpm.[CMS_PQRI_MEASURE_ID] = @MeasureId
		AND cpmc.[START_DATE] <= @Dos
		AND (cpmc.[END_DATE] IS NULL OR cpmc.[END_DATE] > @Dos)
		AND cpm.[EFFECTIVE_DATE] <= @Dos
		AND (cpm.[EXPIRATION_DATE] IS NULL OR cpm.[EXPIRATION_DATE] > @Dos)
		AND (cpmc.[CODE] IS NOT NULL OR cpmc.[MODIFIER] IS NOT NULL)
		AND cpmc.[CODING_SYSTEM] IN ('DG1P1','DG1P2','DG2P1',/*'DG2P2','DG2P3','HCPCS',*/'DQ411')
	ORDER BY 
		cpmc.CMS_PQRI_MEASURE_CODE_ID; 

	IF @ShowDebug <> 0 SELECT * FROM #tempDenominatorList; -- testing

	IF (NOT EXISTS (SELECT 1 FROM #tempDenominatorList))
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'No Denominator Pick List records found';
		RETURN;
	END;

	DECLARE @foundDenominatorGroup1Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1');
	DECLARE @foundDenominatorGroup1Pick2MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2');
	DECLARE @foundDenominatorGroup2Pick1MatchCount INT = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1');
	DECLARE @foundDenominatorQuestionsMatchCount INT   = (SELECT COUNT(*) FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DQ411');
	
	IF @foundDenominatorGroup1Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P1 records';
		RETURN;
	END;

	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG1P2 records';
		RETURN;
	END;

	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN
		SELECT 'Error' = -3, 'Message' = 'Missing Denominator DG2P1 records';
		RETURN;
	END;

	-- IF @foundDenominatorQuestionsMatchCount <= 0
	-- BEGIN
		-- SELECT 'Error' = -3, 'Message' = 'Missing Denominator DQ411 record';
		-- RETURN;
	-- END;

	----------------
	-- Collect our test decision points ---->
	----------------

	-- do we have a Diagnosis for coronary artery disease (ICD-10-CM) listing?
	SET @foundDenominatorGroup1Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	-- OR History of cardiac surgery (CPT): -- *Note: this is a somewhat unique case regarding this MIPS Rule
	DECLARE @foundDenominatorGroup1Pick1MatchCountB INT = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P1'));

	IF @foundDenominatorGroup1Pick1MatchCount <= 0 AND @foundDenominatorGroup1Pick1MatchCountB <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (No Diagnosis for coronary artery disease NOR History of cardiac surgery (CPT))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have a Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM) listing?
	SET @foundDenominatorGroup2Pick1MatchCount = (SELECT COUNT(*) FROM #tempDiagnosisList WHERE [ICD10_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG2P1'));
	IF @foundDenominatorGroup2Pick1MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Diagnosis for myocardial infarction – includes patient that had a prior (within the past 3 years) myocardial infarction (ICD-10-CM))', 'Code' = 'ERR-2-NCA';
		RETURN;
	END;

	-- do we have Patient encounter during the performance period (CPT)?
	SET @foundDenominatorGroup1Pick2MatchCount = (SELECT COUNT(*) FROM #tempProcedureList WHERE [CPT_CODE] IN (SELECT [CODE] FROM #tempDenominatorList WHERE [CODING_SYSTEM] = 'DG1P2'));
	IF @foundDenominatorGroup1Pick2MatchCount <= 0
	BEGIN 
		SELECT 'Result' = 0, 'Message' = CAST(@MeasureId AS VARCHAR(20)) + ': Data completeness Not Met (Patient encounter during the performance period)', 'Code' = 'ERR-3-NPE';
		RETURN;
	END;

	----------------
	-- all Data Completion steps satisified.
	----------------

	IF (SELECT COUNT(*) FROM #tempDenominatorList tdl WHERE tdl.[CODING_SYSTEM] = 'DQ411' AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0) <= 0
		SELECT 'RESULT' = '411', 'QUESTION' = ' ', 'CODE' = '00001';
	ELSE
		SELECT TOP 5
			'411' AS 'RESULT'
			, CAST(@MeasureId AS VARCHAR(20)) + ': ' + [DESCRIPTION] AS 'QUESTION'
			, tdl.[CODE] AS 'CODE'
		FROM 
			#tempDenominatorList tdl
		WHERE 
			tdl.[CODING_SYSTEM] = 'DQ411'
			AND tdl.[DESCRIPTION] IS NOT null AND LEN(tdl.[DESCRIPTION]) > 0
		ORDER BY
			tdl.[CODE];

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '007-B' -- = 211
exec PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B
	@ChartId = 2100113517 -- 2100113748
	,@PqrsNum = '007-B'
begin tran; -- testing
*/
-- End of 02) DACS-3550 - Create or Alter Stored Procedure - [dbo].[PqrsMeasureIsSatisfiedByOneCriteriaAndCoderResponse_Type007B].SQL
GO

-- Start of 01) DACS-3538 - Create or Alter Stored Procedure - [dbo].[sp_Get_DashboardPendingReport].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3538 - Create or Alter Stored Procedure - [dbo].[sp_Get_DashboardPendingReport].SQL
------------------------------------------------------------------------------------
GO

GO

GO

-- =============================================
-- Author: Daniel Bonebrake
-- Create date: 12/3/2015
-- Updated date: 1/31/2018 JohnS: Added #ChartIDs temp table to improve performance
-- Updated date: 10/3/2018 JohnS: Made the following changes:
--   1) The SQL that inserts charts into the #ChartIDs temp table does not include the "TOP" max charts results statement to limit the results to 3001 rows (3000 is the current value for the max charts results). 
--      This could potentially cause millions of rows to be inserted into the #ChartIDs temp table. Added the "TOP" statement in this insert query. 
--   2) The SQL that does include the "TOP" statement is the SELECT statement into the #ChartSubset table. This SQL selects from the CHART table and joins the CHART table to the #ChartIDs table. 
--      The FROM clause should be selecting from the #ChartIDs table and joining the #ChartIDs table to the CHART table. The "TOP" statement was removed from the SQL that selects rows into the #ChartSubset table. 
--   3) In the query that inserts rows into #ImageSubset, added ii.CHART_ID = -1 to the WHERE clause. Rows with a value in the CHART_ID column should not be included in that query.
--   4) In the query that inserts rows into #ImageSubset, added ii.FACILITY_ID = c.FACILITY_ID to the WHERE clause in the sub-query that checks if ii.FACILITY_CHART_ID exists in the CHART table.
--   5) Changed the @cmd variable to only include " UNION " when the value of @m_ReturnCount = 1.
--   6) Created a separate command variable (@cmd3) for storing the SQL that checks the count in the #ChartIDs table and modified the SQL at the bottom of the stored proc to execute @cmd3 + @cmd + @cmd1 when the 
--      value of the @m_ReturnCount = 1. 
-- Description: SQL for pending transactions portion of dashboard
-- =============================================

-- Modified 20230419 - wpippin - added filtering for [FLAGGED_FOR_POST_BILL_AUDIT_DT] (ACS c# = PostBillAuditFlagged) field
-- Modified 20230501 - wpippin - added filtering for logNotes fields indicating flags for the new PBA audit and new PBA flagged for additional audit notes
-- Modified 20230608 - wpippin - revert logNotes fields behavior back to using [CHART].[FLAGGED_FOR_POST_BILL_AUDIT_DT] and add [FLAGGED_FOR_POST_BILL_AUDIT] [bit] NULL behavior.
-- Modified 20230815 - wpippin - added FacilityChartIdentifierList input parameter
-- Modified 20240802 - wpippin - modify parameter @OrderByString to become VARCHAR(100) per JB's instructions at ~ line # 105

CREATE OR ALTER      PROCEDURE [dbo].[sp_Get_DashboardPendingReport]
    @ReturnCount bit = 0,
    @DosFrom date = NULL,
    @DosTo date = NULL,
    @ReceivedFrom date = NULL,
    @ReceivedTo date = NULL,
    @SentFrom date = NULL,
    @SentTo date = NULL,
    @ChartStatuses varchar(50) = '',
    @PendingReasons varchar(MAX) = NULL,
    @Facilities varchar(MAX) = NULL,
    @MedicalRecordNumber varchar(25) = '',
    @FacilityChartIdentifier varchar(25) = '',
    @FacilityAdminChartID varchar(25) = '',       
    @ClinicID varchar(10) = '',
    @PatientClassID int = - 1,
    @LocationCodes varchar(MAX) = NULL,
    @Providers varchar(MAX) = NULL,
    @ObservationDepartments varchar(MAX) = NULL,
    @OrderBy int = 0, -- DOS
    @SortDirection varchar(4) = 'ASC',
    @ChartSearchMaxCount int = 3000,
	@ChartPostBillAuditStatus int = 0,
	@ChartPostBillAuditStartDtFrom date = NULL,
	@ChartPostBillAuditStartDtTo date = NULL,
	@ChartPostBillAuditCompletedDtFrom date = NULL,
	@ChartPostBillAuditCompletedDtTo date = NULL,
	@ChartPostBillAuditFlaggedDtFrom date = NULL,
	@ChartPostBillAuditFlaggedDtTo date = NULL,
	@ChartPostBillAuditFlagged bit = 0,
	@FacilityChartIdentifierList varchar(MAX) = NULL
	
AS
BEGIN
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

DECLARE @Today DATE = GETDATE();

-- Insert statements for procedure here
DECLARE @m_ReturnCount BIT = @ReturnCount
    ,@m_ClinicID VARCHAR(10) = @ClinicID
    ,@m_PatientClassID INT = @PatientClassID
	,@m_ChartPostBillAuditStatus INT = @ChartPostBillAuditStatus
	,@m_ChartPostBillAuditStartDtFrom DATE = @ChartPostBillAuditStartDtFrom
	,@m_ChartPostBillAuditStartDtTo DATE = @ChartPostBillAuditStartDtTo
	,@m_ChartPostBillAuditCompletedDtFrom DATE = @ChartPostBillAuditCompletedDtFrom
	,@m_ChartPostBillAuditCompletedDtTo DATE = @ChartPostBillAuditCompletedDtTo
	,@m_ChartPostBillAuditFlaggedDtFrom DATE = @ChartPostBillAuditFlaggedDtFrom
	,@m_ChartPostBillAuditFlaggedDtTo DATE = @ChartPostBillAuditFlaggedDtTo
	,@m_ChartPostBillAuditFlagged BIT = @ChartPostBillAuditFlagged
    ,@m_ChartStatuses VARCHAR(50) = @ChartStatuses
    ,@m_PendingReasons VARCHAR(MAX) = @PendingReasons
    ,@m_DosFrom DATE = @DosFrom
    ,@m_DosTo DATE = ISNULL(@DosTo, @Today)
    ,@m_ReceivedFrom DATE = @ReceivedFrom
    ,@m_ReceivedTo DATE = ISNULL(@ReceivedTo, @Today)
    ,@m_SentFrom DATE = @SentFrom
    ,@m_SentTo DATE = ISNULL(@SentTo, @Today)
    ,@m_Facilities VARCHAR(MAX) = @Facilities
    ,@m_MedicalRecordNumber VARCHAR(25) = @MedicalRecordNumber
    ,@m_FacilityChartIdentifier VARCHAR(25) = @FacilityChartIdentifier
    ,@m_FacilityAdminChartID VARCHAR(25) = @FacilityAdminChartID
    ,@m_LocationCodes VARCHAR(MAX) = @LocationCodes
    ,@m_Providers VARCHAR(MAX) = @Providers
    ,@m_ObservationDepartments VARCHAR(MAX) = @ObservationDepartments
    ,@m_OrderBy INT = @OrderBy
    ,@m_SortDirection VARCHAR(4) = @SortDirection
    ,@OrderByString VARCHAR(100)
    ,@cmd VARCHAR(MAX) = ''
    ,@cmd2 VARCHAR(MAX) = ''
    ,@cmd1 VARCHAR(MAX) = ''
    ,@cmd3 VARCHAR(MAX) = ''
    ,@WhereClause VARCHAR(MAX) = ''
    ,@AndStr VARCHAR(5) = ''
    ,@m_ChartSearchMaxCount INT = @ChartSearchMaxCount + 1
	,@m_FacilityChartIdentifierList VARCHAR(MAX) = @FacilityChartIdentifierList;
	 
IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  SET @cmd1 += '
SELECT Items = cast(Items as int) 
  INTO #FacilityIDList
FROM dbo.SplitString(''' + @m_Facilities + ''','','')
'
END

IF (@m_ChartStatuses <> '')
BEGIN
  SET @cmd1 += '
SELECT Items = cast(Items as int) 
  INTO #StatusIDList
FROM dbo.SplitString(''' + @m_ChartStatuses + ''','','')
'
END

IF (@m_Providers <> '')
BEGIN
  SET @cmd1 += '
SELECT Items
  INTO #ProviderNPIList
FROM dbo.SplitString(''' + @m_Providers + ''','','')
'
END

  SET @cmd1 += '
SELECT TOP ' + CONVERT(VARCHAR, @m_ChartSearchMaxCount) + ' 
	ii.import_Image_ID,
	f.[NAME] FACILITY
  INTO #ImageSubset
FROM 
  IMPORT_IMAGE ii WITH (NOLOCK)
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = ii.FACILITY_ID
  INNER JOIN #FacilityIDList as t1 ON ii.Facility_ID = t1.Items
WHERE 
  NULLIF(ii.DATE_OF_SERVICE, '''') IS NOT NULL'

IF (@m_DosFrom IS NOT NULL)
BEGIN
  IF (@m_DosFrom = @m_DosTo)
  BEGIN
      SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
  END
  ELSE
  BEGIN
      SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) BETWEEN ''' + CONVERT(varchar, @m_DosFrom) + ''' AND ''' + CONVERT(varchar, @m_DosTo) + ''''
  END
END
ELSE
BEGIN
IF (@m_ReceivedFrom IS NOT NULL)
BEGIN
  IF (@m_ReceivedFrom = @m_ReceivedTo)
  BEGIN
    SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
  END
  ELSE
  BEGIN
    SET @cmd1 += '
  AND DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) BETWEEN ''' + CONVERT(varchar, @m_ReceivedFrom) + ''' AND ''' + CONVERT(varchar, @m_ReceivedTo) + ''''
  END
END
END

SET @cmd1 += '
  AND ii.CHART_ID = -1 
  AND ii.FACILITY_CHART_ID NOT IN 
  (
    SELECT c.FACILITY_CHART_ID
    FROM CHART c WITH (NOLOCK)
    WHERE c.FACILITY_ID = ii.FACILITY_ID 
    AND c.FACILITY_CHART_ID = ii.FACILITY_CHART_ID
  )
'

SET @cmd1 += '
SELECT TOP ' + CONVERT(VARCHAR, @m_ChartSearchMaxCount) + ' CHART_ID
 into #ChartIDs
FROM CHART c WITH (NOLOCK)
'

IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  SET @cmd1 += '
  INNER JOIN #FacilityIDList as t1 on c.Facility_ID = t1.Items'
END

IF (@m_ChartStatuses <> '')
BEGIN
  SET @cmd1 += '
  INNER JOIN #StatusIDList as t2 on c.chart_Status_ID = t2.Items'

  IF (NULLIF(@m_PendingReasons, '') IS NOT NULL)
  BEGIN
  --  SET @WhereClause += '
 --' + @AndStr + ' c.PENDING_REASON_ID IN (' + @m_PendingReasons + ')'
    --SET @AndStr = ' AND '
    SET @WhereClause += '
 ' + @AndStr + ' 0 < CASE WHEN c.CHART_STATUS_ID in (2, 6) THEN 
                (SELECT COUNT(cpr.CHART_PENDING_REASON_ID) from CHART_PENDING_REASON cpr WITH (NOLOCK), SERVICE_AGREEMENT_PENDING_REASON spr WITH (NOLOCK)
                 WHERE cpr.chart_id = c.chart_id AND cpr.SERVICE_AGREEMENT_PENDING_REASON_ID = spr.SERVICE_AGREEMENT_PENDING_REASON_ID 
                 AND spr.PENDING_REASON_ID IN (' +  @m_PendingReasons + '))
                 ELSE 1 END '
    SET @AndStr = ' AND '
  END
END

IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    AND @m_ClinicID <> '-1')
BEGIN
  SET @cmd1 += '
  INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID'
END

IF (@m_MedicalRecordNumber <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.MEDICAL_RECORD_NUM LIKE (''' + @m_MedicalRecordNumber + '%'')'
  SET @AndStr = ' AND '
END

IF (@m_FacilityChartIdentifier <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.FACILITY_CHART_ID LIKE (''' + @m_FacilityChartIdentifier + '%'')'
  SET @AndStr = ' AND '
END  
ELSE
BEGIN
	IF (@m_FacilityChartIdentifierList <> '')
	BEGIN
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N' ', N'');
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N',,', N',');
	  SET @m_FacilityChartIdentifierList = REPLACE(@m_FacilityChartIdentifierList, N',', N''',''');
	  SET @m_FacilityChartIdentifierList = '''' + @m_FacilityChartIdentifierList + '''';

	  SET @WhereClause += ' 
	 ' + @AndStr + 'c.FACILITY_CHART_ID IN (' + @m_FacilityChartIdentifierList + ')';
 
	  SET @AndStr = ' AND ';
	END  
END

IF (@m_FacilityAdminChartID <> '')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + 'c.FACILITY_ADMIN_CHART_ID LIKE (''' + @m_FacilityAdminChartID + '%'')'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_LocationCodes, '') IS NOT NULL)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'EXISTS (
    SELECT *
    FROM dbo.SplitString(''' + @m_LocationCodes + ''','','')
    WHERE ITEMS = c.LOCATION_CODE
  )'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_ObservationDepartments, '') IS NOT NULL)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'c.INITIAL_CHARGE_MASTER_DEPT_ID IN (' + @m_ObservationDepartments + ')'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_ClinicID, '') IS NOT NULL       
    AND @m_ClinicID <> '-1')
BEGIN
  SET @WhereClause += ' 
 ' + @AndStr + '(
    sa.COLLECT_CLINIC = ''N''
    OR c.CLINIC_ID = ''' + @m_ClinicID + '''
  )'
  SET @AndStr = ' AND '
END

IF (NULLIF(@m_Providers, '') IS NOT NULL)
BEGIN

  SET @cmd1 += '
  LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
    and c.physician_ID > -1 
  LEFT JOIN FACILITY_PROFESSIONAL mlp WITH (NOLOCK) ON mlp.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
    and c.NURSE_PRACTITIONER_ID > -1'

  SET @WhereClause += '
  ' + @AndStr + 'EXISTS (
    SELECT *
    FROM #ProviderNPIList
    WHERE ITEMS = fp.UPIR_ID

    UNION

    SELECT *
    FROM #ProviderNPIList
    WHERE ITEMS = mlp.UPIR_ID
  )'
  SET @AndStr = ' AND '
END

IF (@m_DosFrom IS NOT NULL)
BEGIN
  IF (@m_DosFrom = @m_DosTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_DosFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_DosTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_ReceivedFrom IS NOT NULL)
BEGIN
  IF (@m_ReceivedFrom = @m_ReceivedTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.DATE_RECEIVED), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ReceivedTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_SentFrom IS NOT NULL)
BEGIN
  IF (@m_SentFrom = @m_SentTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) = ''' + CONVERT(VARCHAR, @m_SentFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.SENT_DATE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_SentFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_SentTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_PatientClassID > 0)
BEGIN
  SET @WhereClause += '
 ' + @AndStr + 'c.PATIENT_CLASS_ID = ' + CONVERT(VARCHAR, @m_PatientClassID)
  SET @AndStr = ' AND '
END

-- Post Bill Audit filters
IF (@m_ChartPostBillAuditStatus > 0)
BEGIN
  SET @cmd1 += '
  INNER JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
  SET @WhereClause += '
 ' + @AndStr + 'pba.ChartPostBillAuditStatusTypeCode = ' + CONVERT(VARCHAR, @m_ChartPostBillAuditStatus)
  SET @AndStr = ' AND '
END
ELSE
BEGIN
  SET @cmd1 += '
  LEFT JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
END

IF (@m_ChartPostBillAuditStartDtFrom IS NOT NULL)
BEGIN
  IF (@m_ChartPostBillAuditStartDtFrom = @m_ChartPostBillAuditStartDtTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_STARTED), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditStartDtFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_STARTED), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditStartDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditStartDtTo) + ''''
    SET @AndStr = ' AND '
  END
END

IF (@m_ChartPostBillAuditCompletedDtFrom IS NOT NULL)
BEGIN
  IF (@m_ChartPostBillAuditCompletedDtFrom = @m_ChartPostBillAuditCompletedDtTo)
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_COMPLETED), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditCompletedDtFrom) + ''''
    SET @AndStr = ' AND '
  END
  ELSE
  BEGIN
    SET @WhereClause += '
 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.POST_BILL_AUDIT_COMPLETED), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditCompletedDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditCompletedDtTo) + ''''
    SET @AndStr = ' AND '
  END
END

-- Modified 20230608 - wpippin - revert logNotes fields behavior back to using [CHART].[FLAGGED_FOR_POST_BILL_AUDIT_DT] and add [FLAGGED_FOR_POST_BILL_AUDIT] [bit] NULL behavior.
IF (@m_ChartStatuses <> '' AND @m_ChartStatuses like '%5%')
BEGIN
	IF (@m_ChartPostBillAuditFlaggedDtFrom IS NOT NULL)
	BEGIN
	  IF (@m_ChartPostBillAuditFlaggedDtFrom = @m_ChartPostBillAuditFlaggedDtTo)
	  BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.FLAGGED_FOR_POST_BILL_AUDIT_DT), 0) = ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditFlaggedDtFrom) + ''''
		SET @AndStr = ' AND '
	  END
	  ELSE
	  BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, c.FLAGGED_FOR_POST_BILL_AUDIT_DT), 0) BETWEEN ''' + CONVERT(VARCHAR,  @m_ChartPostBillAuditFlaggedDtFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ChartPostBillAuditFlaggedDtTo) + ''''
		SET @AndStr = ' AND '
	  END
	END

	IF (@m_ChartPostBillAuditFlagged IS NOT NULL AND @m_ChartPostBillAuditFlagged = 1)
	BEGIN
		SET @WhereClause += '
	 ' + @AndStr + 'c.FLAGGED_FOR_POST_BILL_AUDIT = 1'
		SET @AndStr = ' AND '
	END
END
--end Post Bill Audit Filters

-- Append where clause to @cmd
IF (@WhereClause <> '')
BEGIN
  SET @cmd1 += '
WHERE ' + @WhereClause
  SET @WhereClause = ''
  SET @AndStr = ''
END

IF (@m_ReturnCount = 1)
BEGIN
    SET @cmd3 += 'SELECT COUNT(*) TOTAL FROM #ChartIDs '
END

IF (@m_ReturnCount = 0)
BEGIN
  SET @cmd1 += '
SELECT c.CHART_ID
  ,c.FACILITY_CHART_ID
  ,c.MEDICAL_RECORD_NUM
  ,c.PATIENT_DOB
  ,c.service_agreement_ID
  ,c.CLIENT_COMMENT
  ,c.CHANGED_DATE_TIME
  ,c.CREATION_DATE_TIME
  ,c.TIME_OF_SERVICE
  ,c.TIME_OF_DIS
  ,c.CODER_COMMENT
  ,c.PATIENT_LAST_NAME
  ,c.PATIENT_FIRST_NAME
  ,c.CHART_STATUS_ID
  ,c.PATIENT_DISPOSITION_ID
  ,c.PENDING_REASON_ID
  ,c.FACILITY_ID
  ,c.SENT_DATE
  ,c.LOCATION_CODE
  ,c.FACILITY_ADMIN_CHART_ID
  ,c.Physician_ID
  ,c.Nurse_Practitioner_ID
  ,c.Patient_Class_ID
  ,c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
  ,c.INITIAL_CHARGE_MASTER_DEPT_ID
  ,f.[NAME] FACILITY
  ,sa.SERVICE_MODEL_CD + CONVERT(varchar(10), up.USER_CLASS_CD) AS ServiceModelCode
  ,up.FIRST_NAME
  ,up.LAST_NAME
  ,c.ASSIGNED_TO_ID
INTO #ChartSubset
FROM #ChartIDs t
  INNER join CHART c WITH (NOLOCK) ON c.chart_ID = t.chart_ID
  INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  INNER JOIN USER_PROFILE up WITH (NOLOCK) ON up.USER_PROFILE_ID = c.ASSIGNED_TO_ID
  INNER JOIN SERVICE_AGREEMENT sa WITH (NOLOCK) ON sa.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID'
END

-- Build the Query
IF (@m_ReturnCount = 0)
BEGIN	
    SET @cmd += '

SELECT c.FACILITY
  ,c.CHART_ID
  ,c.FACILITY_CHART_ID
  ,c.MEDICAL_RECORD_NUM
  ,c.PATIENT_DOB
  ,(
    SELECT TOP 1 IMPORT_IMAGE.CREATION_DATE_TIME
    FROM IMPORT_IMAGE WITH (NOLOCK)
    WHERE IMPORT_IMAGE.FACILITY_CHART_ID = c.FACILITY_CHART_ID
      AND IMPORT_IMAGE.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
    ORDER BY IMPORT_IMAGE.CREATION_DATE_TIME DESC
  ) LAST_IMAGE_RECEIPT_DATE
  ,c.CLIENT_COMMENT
  ,c.CHANGED_DATE_TIME
  ,CASE 
    WHEN (
      c.FACILITY_CHART_ID IN (
        SELECT DISTINCT ii.FACILITY_CHART_ID
        FROM IMPORT_IMAGE ii WITH (NOLOCK)
        WHERE ii.FACILITY_CHART_ID = c.FACILITY_CHART_ID
          AND ii.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID
      )
    )
    THEN ''Yes''
    ELSE ''No''
  END [EMR?]
  ,''Yes'' [Census?]
  ,c.CREATION_DATE_TIME Received
  ,c.TIME_OF_SERVICE DOS
  ,c.TIME_OF_DIS DISCHARGE
  ,cs.[DESCRIPTION] [STATUS]
  ,CASE WHEN c.CHART_STATUS_ID in (2, 6)
    THEN (
      SELECT STUFF(
        (
          SELECT ''|'' + pr.DESCRIPTION
          FROM CHART_PENDING_REASON WITH (NOLOCK),
            SERVICE_AGREEMENT_PENDING_REASON sap WITH (NOLOCK),
            PENDING_REASON pr WITH (NOLOCK)
          WHERE CHART_ID = c.CHART_ID
            AND sap.SERVICE_AGREEMENT_PENDING_REASON_ID = CHART_PENDING_REASON.SERVICE_AGREEMENT_PENDING_REASON_ID
            AND sap.PENDING_REASON_ID = pr.PENDING_REASON_ID
          ORDER BY sap.RANK_VALUE
          FOR XML PATH('''')
        ), 1, 1, '''')
      )
    ELSE ''''
  END [Pending Reason]
  ,pd.[DESCRIPTION] [Patient Disposition]
  ,c.CODER_COMMENT AS [Coder Notes]
  ,c.PATIENT_LAST_NAME + '', '' + c.PATIENT_FIRST_NAME [Patient]
  ,fp.LAST_NAME + '', '' + fp.FIRST_NAME + '' '' + fp.NAME_SUFFIX + '' ('' + fp.EMPLOYEE_IDENTIFIER + '')'' Physician
  ,c.CHART_STATUS_ID
  ,ISNULL(PATIENT_CLASS.DESCRIPTION, ''All'') PatientClass
  ,c.PATIENT_DISPOSITION_ID
  ,c.PENDING_REASON_ID
  ,c.FACILITY_ID
  ,c.SENT_DATE SENT
  ,c.LOCATION_CODE
  ,mlp.LAST_NAME + '', '' + mlp.FIRST_NAME + '' '' + mlp.NAME_SUFFIX + '' ('' + mlp.EMPLOYEE_IDENTIFIER + '')'' [Mid-Level]
  ,sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,cmd.NAME as [InitialObservationDept]
  ,c.FACILITY_ADMIN_CHART_ID
  ,c.ServiceModelCode [Service Model Code]
  ,c.FIRST_NAME [First Name]
  ,c.LAST_NAME [Last Name]
  ,pba.ChartPostBillAuditStatusTypeCode [ChartPostBillAuditStatusTypeCode]
FROM #ChartSubset as c
  LEFT JOIN FACILITY_PROFESSIONAL fp WITH (NOLOCK) ON fp.FACILITY_PROF_ID = c.PHYSICIAN_ID
    and c.physician_ID > -1  -- reduces LReads by 70-90% on Facility_Professional
  LEFT JOIN FACILITY_PROFESSIONAL mlp WITH (NOLOCK) ON mlp.FACILITY_PROF_ID = c.NURSE_PRACTITIONER_ID
    and c.NURSE_PRACTITIONER_ID > -1 '	-- reduces LReads by 70-90% on Facility_Professional 
  + '
  --INNER JOIN FACILITY f WITH (NOLOCK) ON f.FACILITY_ID = c.FACILITY_ID
  INNER JOIN CHART_STATUS cs WITH (NOLOCK) ON cs.CHART_STATUS_ID = c.CHART_STATUS_ID
  LEFT JOIN PATIENT_CLASS WITH (NOLOCK) ON PATIENT_CLASS.PATIENT_CLASS_ID = c.PATIENT_CLASS_ID
  LEFT JOIN PATIENT_DISPOSITION pd WITH (NOLOCK) ON pd.PATIENT_DISPOSITION_ID = c.PATIENT_DISPOSITION_ID
  LEFT JOIN SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE sao WITH (NOLOCK) ON sao.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID = c.OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID
  LEFT JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK) ON cmd.CHARGE_MASTER_DEPT_ID = c.INITIAL_CHARGE_MASTER_DEPT_ID
    and c.INITIAL_CHARGE_MASTER_DEPT_ID > -1 ' -- reduces LReads by 90% on Charge_Master_Department 
  + '
  LEFT JOIN
    (	'-- reduces LReads by 25% on Import_Image (compared to having two subqueries in the SELECT statement)
    + '
      SELECT Facility_Chart_ID, Service_Agreement_ID, MaxCreationDT = max(CREATION_DATE_TIME)
      FROM IMPORT_IMAGE WITH (NOLOCK)
      GROUP BY Facility_Chart_ID, Service_Agreement_ID
    ) as ii on c.facility_Chart_ID = ii.facility_chart_ID
        and c.service_agreement_ID = ii.service_agreement_id'
  + '
  LEFT JOIN ChartPostBillAudit pba ON pba.ChartId = c.CHART_ID'
	  
END

IF (NULLIF(@m_Facilities, '') IS NOT NULL)
BEGIN
  

  --IF (NULLIF(@m_Providers, '') IS NOT NULL)
  --BEGIN
  --  SET @WhereClause += '
  --' + @AndStr + 'EXISTS (
  --  SELECT *
  --  FROM dbo.SplitString(''' + @m_Providers + ''','','')
  --  WHERE ITEMS = fp.UPIR_ID

  --  UNION

  --  SELECT *
  --  FROM dbo.SplitString(''' + @m_Providers + ''','','')
  --  WHERE ITEMS = mlp.UPIR_ID
  --)'
  --  SET @AndStr = ' AND '
  --END

--  -- Append where clause to @cmd
--  IF (@WhereClause <> '')
--  BEGIN
--    SET @cmd += '
--WHERE ' + @WhereClause
--    SET @WhereClause = ''
--    SET @AndStr = ''
--  END

  SET @cmd += '

UNION  '

    IF (@m_ReturnCount = 0)
    BEGIN
      SET @cmd2 += 'SELECT xx.FACILITY
  ,-1 CHART_ID
  ,ii.FACILITY_CHART_ID [Patient No.]
  ,'''' MEDICAL_RECORD_NUM
  ,'''' PATIENT_DOB
  ,'''' LAST_IMAGE_RECEIPT_DATE
  ,ii.CLIENT_COMMENT
  ,'''' CHANGED_DATE_TIME
  ,''Yes'' [EMR?]
  ,''No'' [Census?]
  ,ii.CREATION_DATE_TIME Received
  ,ii.DATE_OF_SERVICE DOS
  ,ii.DATE_OF_DISCHARGE DISCHARGE
  ,''Awaiting census record'' [STATUS]
  ,'''' [Pending Reason]
  ,'''' [Patient Disposition]
  ,'''' [Coder Notes]
  ,'''' [Patient]
  ,'''' [Physician]
  ,-1 CHART_STATUS_ID
  ,'''' PatientClass
  ,-1 PATIENT_DISPOSITION_ID
  ,-1 PENDING_REASON_ID
  ,ii.FACILITY_ID
  ,NULL SENT
  ,NULL LOCATION_CODE
  ,'''' [Mid-Level]
  ,'''' OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,'''' [InitialObservationDept]
  ,'''' FACILITY_ADMIN_CHART_ID
  ,'''' [Service Model Code]
  ,'''' [First Name]
  ,'''' [Last Name] 
  ,NULL [ChartPostBillAuditStatusTypeCode]
FROM #ImageSubset as xx
INNER JOIN IMPORT_IMAGE ii WITH (NOLOCK) on ii.import_image_ID = xx.import_Image_ID'
    END
    ELSE
    BEGIN
        SET @cmd2 += 'SELECT COUNT(*) TOTAL FROM #ImageSubset '
    END

--    IF (@m_DosFrom IS NOT NULL)
--    BEGIN
--      IF (@m_DosFrom = @m_DosTo)
--      BEGIN
--        SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) = ''' + CONVERT(VARCHAR, @m_DosFrom) + ''''
--        SET @AndStr = ' AND '
--      END
--      ELSE
--      BEGIN
--        SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.DATE_OF_SERVICE), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_DosFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_DosTo) + ''''
--        SET @AndStr = ' AND '
--      END
--    END
--    ELSE
--      SET @WhereClause += '
--  ' + @AndStr + 'NULLIF(ii.DATE_OF_SERVICE, '''') IS NOT NULL'
--      SET @AndStr = ' AND '
--      IF (@m_ReceivedFrom IS NOT NULL)
--      BEGIN
--        IF (@m_ReceivedFrom = @m_ReceivedTo)
--        BEGIN
--          SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) = ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''''
--          SET @AndStr = ' AND '
--        END
--        ELSE
--        BEGIN
--          SET @WhereClause += '
--  ' + @AndStr + 'DATEADD(DAY, DATEDIFF(DAY, 0, ii.CREATION_DATE_TIME), 0) BETWEEN ''' + CONVERT(VARCHAR, @m_ReceivedFrom) + ''' AND ''' + CONVERT(VARCHAR, @m_ReceivedTo) + ''''
--          SET @AndStr = ' AND '
--        END
--      END
--
--  -- Append where clause to @cmd2
--  IF (@WhereClause <> '')
--  BEGIN
--    SET @cmd2 += '
--WHERE ' + @WhereClause
--    SET @WhereClause = ''
--    SET @AndStr = ''
--  END
END
ELSE
-- Return empty result set if no facility is selected
BEGIN
  IF (@m_ReturnCount = 0)
  BEGIN
    SET @cmd = '
SELECT NULL FACILITY
  ,NULL CHART_ID
  ,NULL [Patient No.]
  ,NULL MEDICAL_RECORD_NUM
  ,NULL PATIENT_DOB
  ,NULL LAST_IMAGE_RECEIPT_DATE
  ,NULL CLIENT_COMMENT
  ,NULL CHANGED_DATE_TIME
  ,NULL [EMR?]
  ,NULL [Census?]
  ,NULL Received
  ,NULL DOS
  ,NULL DISCHARGE
  ,NULL [STATUS]
  ,NULL [Pending Reason]
  ,NULL [Patient Disposition]
  ,NULL [Coder Notes]
  ,NULL [Patient]
  ,NULL [Physician]
  ,NULL CHART_STATUS_ID
  ,NULL PatientClass
  ,NULL PATIENT_DISPOSITION_ID
  ,NULL PENDING_REASON_ID
  ,NULL FACILITY_ID
  ,NULL SENT
  ,NULL LOCATION_CODE
  ,NULL [Mid-Level]
  ,NULL OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC
  ,NULL [InitialObservationDept]
  ,NULL FACILITY_ADMIN_CHART_ID
  ,NULL [Service Model Code]
  ,NULL [First Name]
  ,NULL [Last Name]
WHERE 1=2'
  END
  ELSE
  BEGIN
    SET @cmd = 'SELECT 0'
  END

--debug
  PRINT '1) Executing the following command.';
  PRINT @cmd;
--end debug

  EXEC(@cmd)
  RETURN
END

IF (@m_ReturnCount = 0)
BEGIN
    SET @OrderByString = CASE @m_OrderBy
            WHEN 0
                THEN 'DOS'
            WHEN 1
                THEN 'c.FACILITY_CHART_ID'
            WHEN 2
                THEN 'c.MEDICAL_RECORD_NUM'
            WHEN 3
                THEN 'RECEIVED'
            WHEN 4
                THEN 'CHANGED_DATE_TIME'
            WHEN 5
                THEN '[EMR?]'
            WHEN 6
                THEN '[Census?]'
            WHEN 7
                THEN 'Received'
            WHEN 8
                THEN 'Status'
            WHEN 9
                THEN '[Pending Reason]'
            WHEN 10
                THEN 'Patient'
            WHEN 11
                THEN 'Physician'
            WHEN 12
                THEN 'DISCHARGE'
            WHEN 13
                THEN 'LAST_IMAGE_RECEIPT_DATE'
            WHEN 14
                THEN 'PatientClass'
            WHEN 15
                THEN 'FACILITY'
            WHEN 16
                THEN 'SENT'
            WHEN 17
                THEN 'LOCATION_CODE'
            WHEN 18
                THEN '[Mid-Level]'
            WHEN 19
                THEN '[InitialObservationDept]'
            WHEN 20
                THEN 'OBSERVATION_PATIENT_ARRIVAL_SOURCE_DESC'
            WHEN 21
                THEN 'FACILITY_ADMIN_CHART_ID'
			WHEN 22
                THEN '[Patient Disposition]'
			WHEN 23
                THEN 'c.PATIENT_DOB'
            ELSE 'DOS'
            END
    SET @OrderByString += CASE @m_SortDirection
            WHEN 'ASC'
                THEN ' ASC'
            ELSE ' DESC'
            END 
			+ ', c.CHART_ID ' + CASE @m_SortDirection WHEN 'ASC' THEN ' ASC' ELSE ' DESC'  END
    SET @cmd2 += '
ORDER BY ' + @OrderByString

  -- debug
  /*
	PRINT '2) Execute the next 3 commands.';
	PRINT '2a @cmd1';
	PRINT @cmd1;
	PRINT '2b @cmd';
	PRINT @cmd;
	PRINT '2c @cmd2';
	PRINT @cmd2;
	*/
  -- end debug

    EXEC (@cmd1 + @cmd + @cmd2);
    RETURN
END
ELSE
BEGIN
SET @cmd = @cmd1 + '

SELECT SUM(TOTAL) 
FROM (
  ' + @cmd3 + @cmd + @cmd2 
  + '
  ) t'

  -- debug
  --PRINT '3) Execute the command.'
  --PRINT @cmd;
  -- end debug

  EXEC(@cmd)
  RETURN
END
END
GO


-- End of 01) DACS-3538 - Create or Alter Stored Procedure - [dbo].[sp_Get_DashboardPendingReport].SQL
GO

-- Start of 01) DACS-3405 - Script - CMS_PQRI_MEASURE and CMS_PQRI_MEASURE_CODE - expire MIPS 76.SQL

------------------------------------------------------------------------------------
-- 01) DACS-3405 - Script - CMS_PQRI_MEASURE and CMS_PQRI_MEASURE_CODE - expire MIPS 76.SQL
------------------------------------------------------------------------------------
GO
-- begin tran; -- testing

--------------------------------------
-- backup table before we work on it
--------------------------------------
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE', @DestTable = 'CMS_PQRI_MEASURE_DACS-3405';
EXEC [dbo].[Maintenance_BackupTable] @SrcTable = 'CMS_PQRI_MEASURE_CODE', @DestTable = 'CMS_PQRI_MEASURE_CODE_DACS-3405';

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ExpirationDate DATETIME = '12-31-2022';

--------------------------------------
--  expire MIPS from CMS_PQRI_MEASURE table
--------------------------------------
DECLARE @measureId INT = (
	SELECT TOP 1 
		[CMS_PQRI_MEASURE_ID]
	FROM 
		[CMS_PQRI_MEASURE] 
	WHERE 
		[PQRS#] = '76' 
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate)
	ORDER BY 
		[CMS_PQRI_MEASURE_ID] DESC
	);

IF @measureId IS NULL OR @measureId < 170
BEGIN 
	SELECT '@measureId is invalid for expiration date given.  exiting.' = @measureId;
	RETURN;
END;

SELECT '@measureId' = @measureId;

DECLARE @startDateOfMips DATETIME = (
	SELECT TOP 1 
		[EFFECTIVE_DATE]
	FROM 
		[CMS_PQRI_MEASURE] 
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @measureId
	);

SELECT '@startDateOfMips' = @startDateOfMips;

IF @startDateOfMips > @ExpirationDate
BEGIN 
	SET @ExpirationDate = @startDateOfMips;
	SELECT 'Adjusted @ExpirationDate' = @ExpirationDate;
END;

UPDATE [CMS_PQRI_MEASURE]
	SET [EXPIRATION_DATE] = @ExpirationDate
WHERE
	[PQRS#] = '76' 
	AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate);
	
DECLARE @CountItemsToProcess INT = (SELECT COUNT(*) FROM [CMS_PQRI_MEASURE] WHERE [PQRS#] = '76' AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @ExpirationDate));

SELECT '#after process (expect 0)' = @CountItemsToProcess

--------------------------------------
--  expire MIPS from CMS_PQRI_MEASURE_CODE table
--------------------------------------
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([END_DATE] IS NULL OR [END_DATE] >= @ExpirationDate)
		AND [CMS_PQRI_MEASURE_ID] = @measureId
	) ;

SELECT '# CMS_PQRI_MEASURE_CODEs to process (expect ~??)' = @CountItemsToProcess

UPDATE [CMS_PQRI_MEASURE_CODE]
	SET [END_DATE] = @ExpirationDate
WHERE
	([END_DATE] IS NULL OR [END_DATE] >= @ExpirationDate)
	AND [CMS_PQRI_MEASURE_ID] = @measureId
	
SET @CountItemsToProcess = (
	SELECT COUNT(*) 
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE
		([END_DATE] IS NULL OR [END_DATE] > @ExpirationDate)
		AND [CMS_PQRI_MEASURE_ID] = @measureId
	) ;

SELECT '#after process (expect 0)' = @CountItemsToProcess

GO

/*
testing:
-- rollback tran; -- testing
-- commit tran; -- testing

select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
select top 200 * from CMS_PQRI_MEASURE_CODE where [CMS_PQRI_MEASURE_ID] = 201
*/
-- End of 01) DACS-3405 - Script - CMS_PQRI_MEASURE and CMS_PQRI_MEASURE_CODE - expire MIPS 76.SQL
GO

-- Start of 01) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureCodeId].SQL

------------------------------------------------------------------------------------
-- 01) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureCodeId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasureCodeByMeasureCodeId] 
	  @MeasureCodeId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- replaces inline SQL used by method public CMSPQRIMeasureCode Load(int measureCodeID)
	/*
       private const string m_Fields = "CMS_PQRI_MEASURE_CODE_ID, CMS_PQRI_MEASURE_ID, CODING_SYSTEM, OPTION_GROUP, " + 
           "CODE, MODIFIER, DESCRIPTION, PLACE_OF_SERVICE, END_DATE, CODE_2, MODIFIER_2 ";

            sql = "SELECT TOP 1 " + m_Fields
                + "FROM CMS_PQRI_MEASURE_CODE WITH (NOLOCK) "
				+ "WHERE CMS_PQRI_MEASURE_CODE_ID=" + measureCodeID;	
	*/
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 1 
		 [CMS_PQRI_MEASURE_CODE_ID]
		,[CMS_PQRI_MEASURE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[PLACE_OF_SERVICE]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE 
		[CMS_PQRI_MEASURE_CODE_ID] = @MeasureCodeId;

END -- end procedure

GO
-- End of 01) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureCodeId].SQL
GO

-- Start of 02) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureId].SQL

------------------------------------------------------------------------------------
-- 02) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureId].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasureCodeByMeasureId] 
	  @MeasureId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- replaces inline SQL used by method public List<CMSPQRIMeasureCode> LoadAllForMeasure(int measureID)
	/*
       private const string m_Fields = "CMS_PQRI_MEASURE_CODE_ID, CMS_PQRI_MEASURE_ID, CODING_SYSTEM, OPTION_GROUP, " + 
           "CODE, MODIFIER, DESCRIPTION, PLACE_OF_SERVICE, END_DATE, CODE_2, MODIFIER_2 ";

			sql = "SELECT " + m_Fields
                + "FROM CMS_PQRI_MEASURE_CODE WITH (NOLOCK) "
				+ "WHERE CMS_PQRI_MEASURE_ID=" + measureID;
	*/
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 [CMS_PQRI_MEASURE_CODE_ID]
		,[CMS_PQRI_MEASURE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[PLACE_OF_SERVICE]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId;

END -- end procedure

GO
-- End of 02) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureId].SQL
GO

-- Start of 01) DACS-3551 - Script to DROP backup tables and SPROCS FROM RevCycleDB database.sql

----------------------------------------------------------------------
-- 01) DACS-3551 - Script to DROP backup tables and SPROCS FROM RevCycleDB database.sql
----------------------------------------------------------------------
GO

/*
get the list of tables and SPROCs to delete:

exec [dbo].[Maintenance_FindSystemObjectsNamesContainingString] @String = 'DACS'

--->>>

TYPE	NAME
P 		spSelectMissingChartPqrs_DACS-3457
	
U 		CHARGE_MASTER_DACS-2863_20231103
U 		CHARGE_MASTER_DACS-2863_20231106_1058
U 		CHARGE_MASTER_DACS-2888
U 		CHARGE_MASTER_DACS-2888a
U 		CHARGE_MASTER_DACS-2889
U 		CHARGE_MASTER_DACS-2889b
U 		CHARGE_MASTER_DACS-2901
U 		CHARGE_MASTER_DACS-2927
U 		CHARGE_MASTER_DACS-2983
U 		CHARGE_MASTER_DACS-3009
U 		CHARGE_MASTER_DACS-3060
U 		CHARGE_MASTER_DACS-3218
U 		CHARGE_MASTER_DACS-3289
U 		CHARGE_MASTER_DACS-3547
U 		CHARGE_MASTER_MODIFIER_DACS-3547
U 		CHARGE_MASTER_MODIFIER_DACS-3547a
U 		ChartAuditAnesthesiaVersionItem-DACS-3270
U 		ChartAuditDemographicVersionItem-DACS-3270
U 		ChartAuditDiagnosisVersionItem-DACS-3270
U 		ChartAuditDocumentationVersionItem-DACS-3270
U 		ChartAuditFacilityLosVersionItem-DACS-3270
U 		ChartAuditPhysicianLosVersionItem-DACS-3270
U 		ChartAuditProcedureVersionItem-DACS-3270
U 		ChartAuditVersionComment-DACS-3270
U 		ChartAuditVersion-DACS-3270
U 		Chart-DACS-3270
U 		ChartPostBillAudit-DACS-3270
U 		CMS_PQRI_MEASURE_CODE_DACS-3405
U 		CMS_PQRI_MEASURE_CODE_DACS-3534
U 		FACILITY_USER_AUTHORIZATION_DACS-2879_AUDIT
U 		FACILITY_USER_AUTHORIZATION_DACS-2879_AUDITb
U 		FACILITY_USER_AUTHORIZATION_DACS-2879_NOAUDIT
U 		FACILITY_USER_AUTHORIZATION_DACS-2879_NOAUDITa
U 		FACILITY_USER_AUTHORIZATION_DACS-2880
U 		FACILITY_USER_AUTHORIZATION_DACS-2880a
U 		FACILITY_USER_AUTHORIZATION_DACS-2928
U 		FACILITY_USER_AUTHORIZATION_DACS-2928a
U 		FACILITY_USER_AUTHORIZATION_DACS-2928b
U 		FACILITY_USER_AUTHORIZATION_DACS-2928c
U 		PENDING_REASON_DACS-3303
U 		PENDING_REASON_DACS-3316
U 		PENDING_REASON_DACS-3401
U 		PHYSICIAN_SERVICE_DACS-2865_20231109_1250
U 		PHYSICIAN_SERVICE_DACS-2902
U 		SERVICE_AGREEMENT_PENDING_REASON_DACS-3401
U 		SERVICE_AGREEMENT_PQRS_DACS-3025Backup
U 		SERVICE_AGREEMENT_PQRS_DACS-3534
U 		SERVICE_AGREEMENT_RATE_TYPE_DACS-3318
U 		SERVICE_AGREEMENT_RATE_TYPE_DACS-3467
U 		USER_PROFILE_DACS-3359

*/

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- begin tran;

	-----------------------------------
	-- see what we are working with
	-----------------------------------
-- exec [dbo].[Maintenance_FindSystemObjectsNamesContainingString] @String = 'DACS' -- SPROC may not be available on production servers


	-----------------------------------
	-- perform the task
	-----------------------------------
DROP PROCEDURE IF EXISTS [dbo].[spSelectMissingChartPqrs_DACS-3457];

DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2863_20231103];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2863_20231106_1058];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2888];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2888a];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2889];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2889b];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2901];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2927];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-2983];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-3009];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-3060];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-3218];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-3289];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_DACS-3547];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_MODIFIER_DACS-3547];
DROP TABLE IF EXISTS [dbo].[CHARGE_MASTER_MODIFIER_DACS-3547a];
DROP TABLE IF EXISTS [dbo].[ChartAuditAnesthesiaVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditDemographicVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditDiagnosisVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditDocumentationVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditFacilityLosVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditPhysicianLosVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditProcedureVersionItem-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditVersionComment-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartAuditVersion-DACS-3270];
DROP TABLE IF EXISTS [dbo].[Chart-DACS-3270];
DROP TABLE IF EXISTS [dbo].[ChartPostBillAudit-DACS-3270];
DROP TABLE IF EXISTS [dbo].[CMS_PQRI_MEASURE_CODE_DACS-3405];
DROP TABLE IF EXISTS [dbo].[CMS_PQRI_MEASURE_CODE_DACS-3534];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2879_AUDIT];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2879_AUDITb];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2879_NOAUDIT];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2879_NOAUDITa];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2880];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2880a];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2928];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2928a];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2928b];
DROP TABLE IF EXISTS [dbo].[FACILITY_USER_AUTHORIZATION_DACS-2928c];
DROP TABLE IF EXISTS [dbo].[PENDING_REASON_DACS-3303];
DROP TABLE IF EXISTS [dbo].[PENDING_REASON_DACS-3316];
DROP TABLE IF EXISTS [dbo].[PENDING_REASON_DACS-3401];
DROP TABLE IF EXISTS [dbo].[PHYSICIAN_SERVICE_DACS-2865_20231109_1250];
DROP TABLE IF EXISTS [dbo].[PHYSICIAN_SERVICE_DACS-2902];
DROP TABLE IF EXISTS [dbo].[SERVICE_AGREEMENT_PENDING_REASON_DACS-3401];
DROP TABLE IF EXISTS [dbo].[SERVICE_AGREEMENT_PQRS_DACS-3025Backup];
DROP TABLE IF EXISTS [dbo].[SERVICE_AGREEMENT_PQRS_DACS-3534];
DROP TABLE IF EXISTS [dbo].[SERVICE_AGREEMENT_RATE_TYPE_DACS-3318];
DROP TABLE IF EXISTS [dbo].[SERVICE_AGREEMENT_RATE_TYPE_DACS-3467];
DROP TABLE IF EXISTS [dbo].[USER_PROFILE_DACS-3359];

	-----------------------------------
	-- double check
	-----------------------------------
-- exec [dbo].[Maintenance_FindSystemObjectsNamesContainingString] @String = 'DACS' -- SPROC may not be available on production servers

-- rollback tran;
-- commit tran;

GO
-- End of 01) DACS-3551 - Script to DROP backup tables and SPROCS FROM RevCycleDB database.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
