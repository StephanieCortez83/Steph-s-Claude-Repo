------------------------------------------------------------------------------------
-- 04) DACS-3208 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListById].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListById] 
	  @MeasureId INT
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;
		
	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('@Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		 cpm.CMS_PQRI_MEASURE_ID
		,cpm.MEASURE_TITLE
		,cpmc.CMS_PQRI_MEASURE_CODE_ID
		,cpmc.CODING_SYSTEM
		,cpmc.OPTION_GROUP
		,cpmc.CODE
		,cpmc.MODIFIER
		,cpmc.[DESCRIPTION]
		,
		CASE 
			WHEN cpmc.END_DATE IS NULL
				THEN '12/31/9999 00:00:00'
			ELSE cpmc.END_DATE 
			END END_DATE
		,cpmc.CODE_2
		,cpmc.MODIFIER_2
		,NULL [ROW_NUMBER]
	FROM 
		CMS_PQRI_MEASURE cpm
		LEFT JOIN CMS_PQRI_MEASURE_CODE cpmc ON cpmc.CMS_PQRI_MEASURE_ID = cpm.CMS_PQRI_MEASURE_ID
	WHERE 
		DATEADD(DAY, DATEDIFF(DAY, 0, @Dos), 0) BETWEEN cpm.EFFECTIVE_DATE AND ISNULL(cpm.EXPIRATION_DATE, @Dos)
		AND cpm.CMS_PQRI_MEASURE_ID = @MeasureId
		AND cpmc.CODING_SYSTEM IN ('CPT_II','HCPCS')
	ORDER BY cpmc.CODE, cpmc.MODIFIER
	;

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
exec [dbo].[SelectCmsPqrsMeasureResultsListById] @MeasureId = 201; -- 51 is the old id
201	76	MIPS CLINICAL QUALITY MEASURES (CQMS)	PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections	B	0	999	2024-01-01	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/