------------------------------------------------------------------------------------
-- 04) DACS-3225 - Create of Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] 
	  @PqrsNum VARCHAR(20)
	, @Dos DATETIME = NULL
WITH EXEC AS CALLER AS
BEGIN

	IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @PqrsNum';
		RETURN;
	END;

	IF @Dos IS NULL
	BEGIN
		SET @Dos = GETDATE();
		PRINT('==> @Dos set to ' + CAST(@Dos AS VARCHAR(40)));
	END;
		
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @MeasureId INT = (
		SELECT TOP 1 
			[CMS_PQRI_MEASURE_ID] 
		FROM 
			[CMS_PQRI_MEASURE]
		WHERE 
			[pqrs#] = @PqrsNum
			AND EFFECTIVE_DATE <= @Dos
			AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE >= @Dos)
		);

	PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );
	
	EXEC SelectCmsPqrsMeasureResultsListById @MeasureId=@MeasureId, @Dos=@Dos;

END -- end procedure

GO

/*
testing:
select top 200 * from CMS_PQRI_MEASURE where [pqrs#] = '76'
select top 200 * from CMS_PQRI_MEASURE_CODE where CMS_PQRI_MEASURE_ID = 201
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = 'THEPQR4'; 
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = 'HCPR27';
exec [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum] @PqrsNum = '76'; 
exec [dbo].[SelectCmsPqrsMeasureResultsListById] @MeasureId = 201; -- 51 is the old id
201	76	MIPS CLINICAL QUALITY MEASURES (CQMS)	PQRS# 76 Prevention of Central Venous Catheter (CVC): Related Bloodstream Infections	B	0	999	2024-01-01	NULL	NULL	NULL	NULL	NULL	0	NULL	NULL	NULL	NULL	NULL	NULL	NULL	NULL
begin tran; -- testing
rollback tran; -- testing
commit tran; -- testing
*/