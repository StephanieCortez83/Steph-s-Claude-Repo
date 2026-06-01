---------------------------------------------------------------------------------------------------------------
-- 03) DACS-4755 - Script - UPDATE Portal_Link Entries to remove hard coded url
---------------------------------------------------------------------------------------------------------------

USE [RevCycleDB] 

UPDATE PORTAL_LINK
SET [URL] = '../../ObservationEvaluationStandAlone.aspx'
WHERE PORTAL_LINK_ID = 439
AND TITLE = 'Observation Stand Alone Tool - Lakeland';

UPDATE PORTAL_LINK
SET [URL] = '../../InfusionInjectionStandAloneTool.aspx'
WHERE PORTAL_LINK_ID = 446
AND TITLE = 'I&I Calculator';