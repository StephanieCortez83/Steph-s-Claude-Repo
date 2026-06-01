----------------------------------------
-- 02) DACS-3131 - SQL Script will remove Denial entries from Group Rights and Defined_Rights table
----------------------------------------
USE [RevCycleDB]
GO

SELECT * FROM [dbo].[GROUP_RIGHTS]
WHERE defined_right_id IN (84,85)

DELETE FROM [dbo].[GROUP_RIGHTS]
WHERE defined_right_id IN (84,85)

DELETE FROM [dbo].[DEFINED_RIGHT]
WHERE DEFINED_RIGHT_ID = 84
AND [NAME] = 'Allow User Access to Denial Management Module'

DELETE FROM [dbo].[DEFINED_RIGHT]
WHERE DEFINED_RIGHT_ID = 85
AND [NAME] = 'Allow Denial Management Administration'