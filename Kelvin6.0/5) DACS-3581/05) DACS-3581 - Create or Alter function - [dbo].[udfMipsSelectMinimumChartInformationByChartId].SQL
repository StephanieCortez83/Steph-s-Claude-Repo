----------------------------------------
-- 05) DACS-3581 - Create or Alter function - [dbo].[udfMipsSelectMinimumChartInformationByChartId].SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- drop type 
DROP TYPE IF EXISTS tMipsChartMinimumInfo;

CREATE TYPE tMipsChartMinimumInfo AS TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------


CREATE or ALTER FUNCTION [dbo].[udfMipsSelectMinimumChartInformationByChartId]
(
	 @ChartId INT
)
RETURNS @ChartInfo TABLE
(
	 ChartId INT
	,ServiceAgreementId INT
	,TimeOfService DATETIME NULL
	,Gender VARCHAR(32) NULL
	,PatientDob DATETIME NULL
	,PatientAge INT NULL
	,PatientClassId INT NULL
	,UseTelehealth BIT NULL
)
WITH EXECUTE AS CALLER
AS
BEGIN

	INSERT INTO 
		@ChartInfo	
	SELECT TOP 1
		 [CHART_ID] AS ChartId
		,[SERVICE_AGREEMENT_ID] AS ServiceAgreementId
		,[TIME_OF_SERVICE] AS TimeOfService
		,[GENDER] AS Gender
		,[PATIENT_DOB] AS PatientDob
		,[PATIENT_AGE] AS PatientAge
		,[PATIENT_CLASS_ID] AS PatientClassId
		,[USE_TELEHEALTH] AS UseTelehealth
	FROM 
		[dbo].[CHART]
	WHERE 
		[CHART_ID] = @ChartId;

	RETURN;
END;

GO

/*
-- testing
DECLARE @MipsChartMinimumInfo tMipsChartMinimumInfo;
INSERT INTO @MipsChartMinimumInfo SELECT * FROM dbo.udfMipsSelectMinimumChartInformationByChartId(10991611);
SELECT * FROM @MipsChartMinimumInfo
*/


