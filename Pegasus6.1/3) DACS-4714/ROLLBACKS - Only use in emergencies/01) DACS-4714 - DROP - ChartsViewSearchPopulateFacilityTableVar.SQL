----------------------------------------
-- 01) DACS-4714 - DROP - ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv.SQL
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

DROP PROCEDURE IF EXISTS ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv;

PRINT 'Procedure ChartsViewSearchPopulateFacilityTableVarByUserProfileIdAndFacilityIdCsv dropped.'

GO
