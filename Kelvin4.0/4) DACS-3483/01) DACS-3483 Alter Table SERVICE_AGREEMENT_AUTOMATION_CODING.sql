------------------------------------------------------------------------------------
-- 01) DACS-3483 - Alter table SERVICE_AGREEMENT_AUTOMATION_CODING to add new columns
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

ALTER TABLE 
	SERVICE_AGREEMENT_AUTOMATION_CODING
ADD 
	COLLECT_ADDITIONAL_PROCEDURES bit null,
	COLLECT_ADDITIONAL_PROCEDURES_EFFECTIVE_DATE datetime null,
	COLLECT_ADDITIONAL_PROCEDURES_EXPIRATION_DATE datetime null