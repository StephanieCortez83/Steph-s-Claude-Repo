------------------------------------------------------------------------------------
-- 02) DACS-3358 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqriModifiersForCptByMeasureIdAndCpt].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqriModifiersForCptByMeasureIdAndCpt] 
	  @CmsPqriMeasureId INT
	  , @CptCode VARCHAR(5)
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- replacement for inline SQL used within method "public string GetModifiersForCpt(int cmsPqriMeasureId, string cptCode)" of ACS file "\ACS\CCSBusinessObjects\DAO\CMSRules\CMSPQRIMeasureDAO.cs"
	----------------

	----------------
	-- validate parameters
	----------------
	IF @CmsPqriMeasureId IS NULL OR @CmsPqriMeasureId <= 0
	BEGIN
		PRINT('Bad CmsPqriMeasureId value');
		RETURN;
	END;

	IF @CptCode IS NULL OR LEN(@CptCode) <= 0
	BEGIN
		PRINT('Bad CptCode value');
		RETURN;
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		MODIFIER
	FROM 
		CMS_PQRI_MEASURE_CODE WITH (NOLOCK) 
	WHERE CMS_PQRI_MEASURE_ID=@CmsPqriMeasureId
		AND CODING_SYSTEM IN ('CPT_II', 'HCPCS')
		AND CODE=@CptCode
		AND MODIFIER IS NOT NULL
	UNION
	SELECT 
		MODIFIER_2
	FROM 
		CMS_PQRI_MEASURE_CODE WITH (NOLOCK) 
	WHERE CMS_PQRI_MEASURE_ID=@CmsPqriMeasureId
		AND CODING_SYSTEM IN ('CPT_II', 'HCPCS')
		AND CODE_2=@CptCode
		AND MODIFIER_2 IS NOT NULL;
								 
END -- end procedure

GO

/*
testing:
EXEC SelectCmsPqriModifiersForCptByMeasureIdAndCpt @CmsPqriMeasureId = 202, @CptCode = 'G2092' 
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/