---------------------------------------------------------
-- 01) DACS-1892 - create procedure - ChartExists().sql
---------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE OR ALTER PROCEDURE [dbo].[ChartExists]
	@ChartId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF EXISTS(
		SELECT 
			TOP 1 [CHART_ID] 
		FROM 
			[dbo].[CHART] WITH(NOLOCK) 
		WHERE 
			[CHART_ID] = @ChartId
		)
	SELECT 1
ELSE
	SELECT 0

GO
