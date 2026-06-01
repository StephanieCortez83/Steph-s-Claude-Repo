------------------------------------------------------------------------------------
-- 04) DACS-3417 - Create or Alter Stored Procedure - [dbo].[SelectCmsPqrsMeasureResultsListByPqrsNum].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

------------------------------
-- backup the original stored procedure
------------------------------
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum', @DestProc = 'SelectCmsPqrsMeasureResultsListByPqrsNum_DACS-3417';
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
		-- PRINT('==> @Dos set to ' + CAST(@Dos AS VARCHAR(40)));	-- DACS-3417, 08/19/2024 (pippin)
	END;

	DECLARE @dateOfService DATE = CAST(@Dos AS DATE);			-- DACS-3417, 08/19/2024 (pippin) - per mr. burge's suggestion of matching field types
		
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
			AND ([EFFECTIVE_DATE] IS NULL OR [EFFECTIVE_DATE] <= @dateOfService)	-- DACS-3417, 08/19/2024 (pippin)
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] > @dateOfService)
		);

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)

	IF @MeasureId IS NULL OR @MeasureId <= 0
	BEGIN
		SELECT 'Error' = -1, 'Message' = 'bad @MeasureId';
		RETURN;
	END;

	-- PRINT('==> @MeasureId = ' + CAST(@MeasureId AS VARCHAR(50)) );	-- DACS-3417, 08/19/2024 (pippin)
	
	EXEC SelectCmsPqrsMeasureResultsListById @MeasureId=@MeasureId, @Dos=@Dos;

END -- end procedure

GO


