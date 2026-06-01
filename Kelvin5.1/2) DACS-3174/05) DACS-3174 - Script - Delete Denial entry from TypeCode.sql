----------------------------------------
-- 04) DACS-3174 - SQL Script will DELETE Denial entry for type code
----------------------------------------
USE [RevCycleDB]
GO

DELETE FROM dbo.[TYPE_CODE] WHERE [KEY] = 'DenialClaim'
