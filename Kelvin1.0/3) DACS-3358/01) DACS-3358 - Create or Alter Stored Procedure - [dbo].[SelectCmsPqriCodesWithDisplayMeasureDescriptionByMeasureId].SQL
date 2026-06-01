------------------------------------------------------------------------------------
-- 01) DACS-3358 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriCodesWithDisplayMeasureDescriptionByMeasureId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriCodesWithDisplayMeasureDescriptionByMeasureId] 
	  @CmsPqriMeasureId INT
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- replacement for inline SQL used within method "public List<ListItem> GetPqrsCodesForMeasure(int cmsPqriMeasureId)" of ACS file "\ACS\CCSBusinessObjects\DAO\CMSRules\CMSPQRIMeasureDAO.cs"
	----------------

	----------------
	-- validate parameters
	----------------
	IF @CmsPqriMeasureId IS NULL OR @CmsPqriMeasureId <= 0
	BEGIN
		PRINT('Bad CmsPqriMeasureId value');
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		CODE
		, MEASURE_TITLE
	FROM 
		CMS_PQRI_MEASURE CPM
		JOIN CMS_PQRI_MEASURE_CODE CPMC ON CPMC.CMS_PQRI_MEASURE_ID = CPM.CMS_PQRI_MEASURE_ID
	WHERE 
		CPM.CMS_PQRI_MEASURE_ID=@CmsPqriMeasureId
		AND CODING_SYSTEM IN ('CPT_II', 'HCPCS', 'OTHER')
		AND CODE IS NOT NULL
	UNION
	SELECT 
		CODE_2
		, MEASURE_TITLE
	FROM 
		CMS_PQRI_MEASURE CPM
		JOIN CMS_PQRI_MEASURE_CODE CPMC ON CPMC.CMS_PQRI_MEASURE_ID = CPM.CMS_PQRI_MEASURE_ID
	WHERE 
		CPM.CMS_PQRI_MEASURE_ID=@CmsPqriMeasureId
		AND CODING_SYSTEM IN ('CPT_II', 'HCPCS')
		AND CODE_2 IS NOT NULL
	ORDER BY 
		CODE;
								 
END -- end procedure

GO

/*
testing:
EXEC SelectCmsPqriCodesWithDisplayMeasureDescriptionByMeasureId @CmsPqriMeasureId = 202
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/