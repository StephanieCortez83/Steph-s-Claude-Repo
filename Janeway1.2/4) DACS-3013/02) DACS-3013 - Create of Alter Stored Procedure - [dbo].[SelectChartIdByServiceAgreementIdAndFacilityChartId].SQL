------------------------------------------------------------------------------------
-- 02) DACS-3013 - Create of Alter Stored Procedure - [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId] 
	  @SAId INT
	, @FacilityChartId varchar(50)
WITH EXEC AS CALLER AS
BEGIN

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		PRINT('bad @SAId');
		SELECT 'ERROR' = -1;
		RETURN 
	END;
		
	IF @FacilityChartId IS NULL OR LEN(@FacilityChartId) <= 0
	BEGIN
		PRINT('bad @FacilityChartId');
		SELECT 'ERROR' = -1;
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT top 1
		CHART_ID
	FROM 
		CHART
	WHERE 
	    SERVICE_AGREEMENT_ID= @SAId
		AND FACILITY_CHART_ID= @FacilityChartId;
			
END; -- end procedure


GO


/*
testing:
EXEC [dbo].[SelectChartIdByServiceAgreementIdAndFacilityChartId] 
			  @SAId = 93
			, @FacilityChartId ='FacChID2086061'
*/