------------------------------------------------------------------------------------
-- 01) DACS-3415 - Script - Modify CHARGE_MASTER_CATEGORY table and add a column VALIDATION_CATEGORY
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

ALTER TABLE 
	CHARGE_MASTER_CATEGORY
ADD 
	VALIDATION_CATEGORY BIT DEFAULT 0