------------------------------------------------------------------------------------
-- 06) DACS-3230 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasures].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasures] 
WITH EXEC AS CALLER AS
BEGIN

	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	------------------------------------------------------
	/*
	 replaces inline SQL from LoadAllForED(...) of "\CCSBusinessObjects\DAO\CMSRules\\CMSPQRIMeasureDAO.cs" within ACS project
	  original const string sql = "select " + m_Fields
           + "from CMS_PQRI_MEASURE WITH (NOLOCK) "
		   //+ "where @ActiveOnly=0 or dateadd(day, datediff(day, 0, getdate()), 0) between EFFECTIVE_DATE and isnull(EXPIRATION_DATE, getdate())"
		   + "order by PQRS#";  
	*/
	------------------------------------------------------

		
    SELECT
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
	ORDER BY 
		[PQRS#];

	
END -- end procedure

GO

/*
testing:
exec [dbo].[SelectCmsPqriMeasures] 

*/