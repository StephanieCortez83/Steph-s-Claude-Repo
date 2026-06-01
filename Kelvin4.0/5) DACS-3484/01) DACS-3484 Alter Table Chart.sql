------------------------------------------------------------------------------------
-- 01) DACS-3484 - Script - Alter table Chart to add new columns
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

ALTER TABLE 
	dbo.[Chart]
ADD 
	ADDITIONAL_PROCEDURE_CODING_RECEIVED bit null,
	ADDITIONAL_PROCEDURE_CODING_RECEIVED_DATE_TIME datetime null
GO
