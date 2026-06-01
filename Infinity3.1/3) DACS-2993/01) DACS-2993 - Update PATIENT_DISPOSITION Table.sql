----------------------------------------
-- 01) DACS-2993 - SQL Script - Update Patient Disposition for Left Without Being Seen from False to true
----------------------------------------
USE RevCycleDB
GO

UPDATE
	PATIENT_DISPOSITION
SET
	OUTPATIENT_IND = 1
WHERE
	PATIENT_DISPOSITION_ID = 11
