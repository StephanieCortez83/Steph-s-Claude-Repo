----------------------------------------------------------------
-- 01) DACS-2606 - Alter Procedure - dbo.ChartSelectFlaggedForPbaByChartId.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ChartSelectFlaggedForPbaByChartId]
	  @ChartId int
	
AS
	SELECT 
		count([CHART_ID])
	FROM
		[dbo].[CHART] WITH (NOLOCK)
	WHERE
		[CHART_ID] = @ChartId
		AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] IS NOT NULL
		AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] >= DATEADD(day, -14, GETDATE())

GO

/*
test:
exec [dbo].[ChartSelectFlaggedForPbaByChartId] @ChartId= 2100101604

set the date for testing as needed on QA:
begin tran;
update
	[dbo].[CHART]
SET 
	[FLAGGED_FOR_POST_BILL_AUDIT_DT] = NULL
WHERE
	[CHART_ID] = 2100101604
	AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] IS NOT NULL
	AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] >= DATEADD(day, -14, GETDATE())
--commit tran;
--rollback tran;
*/
