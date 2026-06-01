--------------------------------------------------------------------
-- 01) DACS-2268 - create Index (StatusTypeCode plus DTLastUpdated) - ChartPostBillAudit.sql
--------------------------------------------------------------------

/*
If the creation of the following index fails, that is acceptible.
*/

USE [RevCycleDB]
GO

CREATE INDEX ix_ChartPostBillAudit_CPBAStatusTypeCode_DTLastUpdated_INCL  
	ON ChartPostBillAudit (ChartPostBillAuditStatusTypeCode, DateTimeLastUpdated)   
       INCLUDE (ChartId, ChartPostBillAuditReasonTypeCode)
	   
GO
	   