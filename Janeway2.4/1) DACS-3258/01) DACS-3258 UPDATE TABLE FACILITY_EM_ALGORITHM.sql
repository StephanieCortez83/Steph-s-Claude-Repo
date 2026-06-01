----------------------------------------------------
-- 01) DACS-3258 - SQL Script - UPDATE table FACILITY_EM_ALGORITHM from "T-System - Standard" to "CorroEnhanced Points Tool"
----------------------------------------------------
USE [RevCycleDB]
GO

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

UPDATE FACILITY_EM_ALGORITHM
SET DESCRIPTION = 'CorroEnhanced Points Tool'
WHERE DESCRIPTION = 'T-System - Standard'