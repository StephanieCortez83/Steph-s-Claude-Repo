--------------------------------------------------------------
-- 02) DACS-1654 - update table CPT_CHANGE_REASON.sql
--------------------------------------------------------------
USE [RevCycleDB]
GO

BEGIN TRANSACTION

UPDATE 
	[RevCycleDB].[dbo].[CPT_CHANGE_REASON]
SET 
	[EFFECTIVE_DATE] = '06-01-2022'
WHERE
	[CPT_CHANGE_REASON_ID] <= 10

COMMIT TRANSACTION
-- ROLLBACK TRANSACTION

GO
