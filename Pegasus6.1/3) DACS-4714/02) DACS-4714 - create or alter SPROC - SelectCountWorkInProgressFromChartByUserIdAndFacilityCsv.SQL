----------------------------------------
-- 02) DACS-4714 - create or alter SPROC - SelectCountWorkInProgressFromChartByUserIdAndFacilityCsv.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCountWorkInProgressFromChartByUserIdAndFacilityCsv]
    @UserID INT
  , @FacilityCsv NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	SELECT
		COUNT([CHART_ID]) AS WIP
    FROM 
		[CHART]
    WHERE 
		[ASSIGNED_TO_ID] = @UserID
		AND [CHART_STATUS_ID] = 1
		AND [FACILITY_ID] IN (SELECT DISTINCT
								TRY_PARSE(RTRIM(LTRIM(value))AS INT)
                               FROM STRING_SPLIT(@FacilityCsv, ',')
                               WHERE LEN(RTRIM(LTRIM(value))) > 0 );
	
END;
GO

PRINT('SPROC [[dbo].[SelectCountWorkInProgressFromChartByUserIdAndFacilityCsv]] created.');
GO

