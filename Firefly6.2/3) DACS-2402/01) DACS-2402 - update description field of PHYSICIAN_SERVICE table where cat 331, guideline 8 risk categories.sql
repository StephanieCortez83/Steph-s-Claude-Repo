------------------------------------------------------
-- 01) DACS-2402 - update description field of PHYSICIAN_SERVICE table where cat 331, guideline 8 risk categories.sql
-- Does NOT have to follow normal ACS workflow.  Can be executed on production databases when approved.
------------------------------------------------------
Use RevCycleDB
GO

/*
-------------------------------------------
previous message
	<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>
change to new message:
	<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter, dosage changes to current prescriptions, instructions to<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; stop taking a prescription medication, and prescription medications considered but ultimately not given)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>

Expect 14 records to be updated.
	
For DBAs should they need such:
	
SELECT TOP (100) *
FROM 
	[RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
where 
	[PHYSICIAN_SERVICE_GUIDELINE_ID] = 8
	AND [DESCRIPTION] LIKE '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (%'
	AND PLAN_ID = 1
	AND CATEGORY_ID = 3
	AND SUBCATEGORY_ID = 3
	AND MINOR_CATEGORY = 1
	AND (EFFECTIVE_DATE = '2022-09-01' AND EXPIRATION_DATE = '2099-12-31')	
	
-------------------------------------------
*/

UPDATE [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
	SET [DESCRIPTION] = '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter, dosage changes to current prescriptions, instructions to<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; stop taking a prescription medication, and prescription medications considered but ultimately not given)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>'
WHERE
	[PHYSICIAN_SERVICE_GUIDELINE_ID] = 8
	AND [DESCRIPTION] LIKE '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (%'
	AND PLAN_ID = 1
	AND CATEGORY_ID = 3
	AND SUBCATEGORY_ID = 3
	AND MINOR_CATEGORY = 1
	AND (EFFECTIVE_DATE = '2022-09-01' AND EXPIRATION_DATE = '2099-12-31')

GO