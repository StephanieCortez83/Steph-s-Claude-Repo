------------------------------------------------------------------------------------
-- 02) DACS-DACS-3396 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriMeasureCodeByMeasureId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriMeasureCodeByMeasureId] 
	  @MeasureId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- replaces inline SQL used by method public List<CMSPQRIMeasureCode> LoadAllForMeasure(int measureID)
	/*
       private const string m_Fields = "CMS_PQRI_MEASURE_CODE_ID, CMS_PQRI_MEASURE_ID, CODING_SYSTEM, OPTION_GROUP, " + 
           "CODE, MODIFIER, DESCRIPTION, PLACE_OF_SERVICE, END_DATE, CODE_2, MODIFIER_2 ";

			sql = "SELECT " + m_Fields
                + "FROM CMS_PQRI_MEASURE_CODE WITH (NOLOCK) "
				+ "WHERE CMS_PQRI_MEASURE_ID=" + measureID;
	*/
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 [CMS_PQRI_MEASURE_CODE_ID]
		,[CMS_PQRI_MEASURE_ID]
		,[CODING_SYSTEM]
		,[OPTION_GROUP]
		,[CODE]
		,[MODIFIER]
		,[DESCRIPTION]
		,[PLACE_OF_SERVICE]
		,[END_DATE]
		,[CODE_2]
		,[MODIFIER_2]
	FROM 
		[CMS_PQRI_MEASURE_CODE]
	WHERE 
		[CMS_PQRI_MEASURE_ID] = @MeasureId;

END -- end procedure

GO
