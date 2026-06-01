------------------------------------------------------------------------------------
-- 05) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureByMeasureId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasureByMeasureId] 
	@measureId INT
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	------------------------------------------------------
	/*
	 replaces inline SQL from Load(...) of "\CCSBusinessObjects\DAO\CMSRules\CMSPQRIMeasureDAO.cs" within ACS project
			sql = "SELECT " + m_Fields sdsdsdsfsdfffdsfds
               + "FROM CMS_PQRI_MEASURE WITH (NOLOCK) "
               + "WHERE CMS_PQRI_MEASURE_ID=" + measureID;	*/
	------------------------------------------------------

	SELECT TOP 1
		  [CMS_PQRI_MEASURE_ID]
		, [PQRS#]
		, [MEASURE_TOPIC]
		, [MEASURE_TITLE]
		, [GENDER]
		, [FROM_AGE]
		, [TO_AGE]
		, [EFFECTIVE_DATE]
		, [EXPIRATION_DATE]
    FROM 
		[CMS_PQRI_MEASURE]
    WHERE 
		[CMS_PQRI_MEASURE_ID] = @measureId;

	
END -- end procedure

GO

/*
testing:
exec [dbo].[SelectCmsPqriMeasureByMeasureId] @measureId = 11


*/