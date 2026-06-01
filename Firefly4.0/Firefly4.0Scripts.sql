USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2268 - create Index (StatusTypeCode plus DTLastUpdated) - ChartPostBillAudit.sql

--------------------------------------------------------------------
-- 01) DACS-2268 - create Index (StatusTypeCode plus DTLastUpdated) - ChartPostBillAudit.sql
--------------------------------------------------------------------

/*
If the creation of the following index fails, that is acceptible.
*/

GO

CREATE INDEX ix_ChartPostBillAudit_CPBAStatusTypeCode_DTLastUpdated_INCL  
	ON ChartPostBillAudit (ChartPostBillAuditStatusTypeCode, DateTimeLastUpdated)   
       INCLUDE (ChartId, ChartPostBillAuditReasonTypeCode)
	   
GO
	   
-- End of 01) DACS-2268 - create Index (StatusTypeCode plus DTLastUpdated) - ChartPostBillAudit.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
