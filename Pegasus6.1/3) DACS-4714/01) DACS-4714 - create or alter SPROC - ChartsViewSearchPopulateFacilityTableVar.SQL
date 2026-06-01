----------------------------------------
-- 01) DACS-4714 - create or alter SPROC - ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT 1 FROM sys.types WHERE is_table_type = 1 AND name = 'SearchFacilityAuthType')
BEGIN
    PRINT 'Table type [SearchFacilityAuthType] exists. DROPPING...'
	DROP PROCEDURE IF EXISTS ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv;
	DROP TYPE SearchFacilityAuthType;
END;

PRINT 'Table type [SearchFacilityAuthType] does not exist. Creating..'
CREATE TYPE SearchFacilityAuthType AS TABLE (ID INT, CODER_AUTHORIZED_SERVICE_CODE INT);
GO

CREATE OR ALTER PROCEDURE [dbo].[ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv]
	 @UserProfileId INT
	,@FacilityIdsCsv VARCHAR(MAX) = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	DECLARE @today DATETIME = DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0);

	IF @FacilityIdsCsv IS NULL OR LEN(@FacilityIdsCsv) <= 0
		SELECT DISTINCT
			 [FACILITY_ID]
			,[CODER_AUTHORIZED_SERVICE_CODE]
		FROM
			[FACILITY_USER_AUTHORIZATION]
		WHERE
			[USER_PROFILE_ID] = @UserProfileId
			AND @today BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]
	ELSE
	BEGIN
		SELECT DISTINCT
			 [FACILITY_ID]
			,[CODER_AUTHORIZED_SERVICE_CODE]
		FROM
			[FACILITY_USER_AUTHORIZATION]
		WHERE
			[USER_PROFILE_ID] = @UserProfileId
			AND @today BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]
			AND [FACILITY_ID] IN (SELECT [value] FROM STRING_SPLIT(@FacilityIdsCsv, ',') WHERE [value] IS NOT NULL AND LEN(value) > 0)
	END;

/*
Usage:
exec [dbo].[ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv]
	 @UserProfileId = 13103 -- WPIPPIN

exec [dbo].[ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv]
	 @UserProfileId = 13103
	 ,@FacilityIdsCsv = '499,478,472,454,449,431,417,412,405,404,401,398,394,389,377,376,370,368,362'
*/
END

GO
