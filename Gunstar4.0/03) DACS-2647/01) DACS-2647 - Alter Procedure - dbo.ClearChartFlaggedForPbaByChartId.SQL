----------------------------------------------------------------
-- 01) DACS-2647 - Alter Procedure - dbo.ClearChartFlaggedForPbaDTByChartId.SQL
----------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[ClearChartFlaggedForPbaDTByChartId]
	  @ChartId INT
	
AS

	IF @ChartId > 0
	BEGIN
		UPDATE
			[dbo].[CHART]
		SET 
			[FLAGGED_FOR_POST_BILL_AUDIT_DT] = NULL
		WHERE
			[CHART_ID] = @ChartId;
	END;
		
	SELECT
		COUNT(CHART_ID)
	FROM
		[dbo].[CHART] WITH (NOLOCK)
	WHERE
		[CHART_ID] = @ChartId
		AND [FLAGGED_FOR_POST_BILL_AUDIT_DT] IS NULL;

GO

/*
test:
exec [dbo].[ClearChartFlaggedForPbaDTByChartId] @ChartId= 2100101604

set the date for testing as needed on QA:
begin tran;
update
	[dbo].[CHART]
SET 
	[FLAGGED_FOR_POST_BILL_AUDIT_DT] = NULL
WHERE
	[CHART_ID] = 2100101604
--commit tran;
--rollback tran;
*/
