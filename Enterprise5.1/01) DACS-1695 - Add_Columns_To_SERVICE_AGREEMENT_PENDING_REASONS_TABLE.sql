----------------------------------------------------
-- DACS-1695 - Add 3 new columns to accomodate new
-- workflows for ServiceAgreementPendingReasons.aspx
----------------------------------------------------

USE [RevCycleDB]
GO

BEGIN TRAN

SELECT TOP (1) 1 FROM [dbo].[SERVICE_AGREEMENT_PENDING_REASON] WITH (TABLOCKX)

ALTER TABLE 
	[dbo].[SERVICE_AGREEMENT_PENDING_REASON]
ADD 
	[CHANGE_STATUS] [BIT] NULL
	,[CHART_STATUS_CHANGE_ID] [INT] NULL
    ,[PENDING_REASON_CHANGE_ID] [INT] NULL;


COMMIT TRAN
--ROLLBACK TRANSACTION
GO