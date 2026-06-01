------------------------------------------------------------------------------------
-- 02) DACS-3417 - Create or Alter Stored Procedure - [dbo].[spSelectMissingChartPqrs].SQL
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
EXEC [dbo].[Maintenance_BackupProcedure] @SrcProc = 'spSelectMissingChartPqrs', @DestProc = 'spSelectMissingChartPqrs_DACS-3417';
GO

CREATE OR ALTER   PROCEDURE [dbo].[spSelectMissingChartPqrs]
	@ChartId int
WITH EXEC AS CALLER
AS

SET NOCOUNT ON							-- DACS-3457 - 20240723 - pippin
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @chart_id INT =@ChartId;
DECLARE @RequiredMeasures table
(
  CMS_PQRI_MEASURE_ID int,
  MEASURE_TITLE varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  CMS_PQRI_MEASURE_CODE_ID int,
  CODING_SYSTEM varchar(20),
  OPTION_GROUP numeric(18,0),
  CODE varchar(20),
  MODIFIER varchar(20),
  [DESCRIPTION] varchar(4000), 			-- DACS-3457 - 20240723 - pippin - increases field width
  END_DATE date,
  CODE_2 varchar(6),
  MODIFIER_2 varchar(20),
  MEASURE_TOOLTIP varchar(4000), 		-- DACS-3417 - 20240830 - pippin - added field
  MEASURE_HOTSHEET_URI varchar(1000), 	-- DACS-3417 - 20240830 - pippin - added field
  [ROW_NUMBER] bigint
)

INSERT INTO @RequiredMeasures(CMS_PQRI_MEASURE_ID, MEASURE_TITLE, CMS_PQRI_MEASURE_CODE_ID, CODING_SYSTEM, OPTION_GROUP, CODE, MODIFIER, [DESCRIPTION], END_DATE, CODE_2, MODIFIER_2, MEASURE_TOOLTIP, MEASURE_HOTSHEET_URI, [ROW_NUMBER])
  EXEC [spSelectChartPqrsTest1] @ChartId=@chart_id

SELECT *
FROM @RequiredMeasures rm
WHERE (SELECT COUNT(*)
       FROM PHYSICIAN_PROCEDURE_EVALUATION ppe
         JOIN CHARGE_MASTER cm on cm.CHARGE_MASTER_ID=ppe.PHYSICIAN_PROCEDURE_ID
         JOIN CMS_PQRI_MEASURE_CODE cpmc on cpmc.CMS_PQRI_MEASURE_ID=rm.CMS_PQRI_MEASURE_ID
       WHERE CHART_ID=@chart_id
         AND cm.CHARGE_MASTER_USAGE_CODE=9
         AND cpmc.CODING_SYSTEM in ('CPT_II', 'HCPCS')
         AND cm.CPT_CODE=cpmc.CODE
         AND ppe.MODIFIERS=isnull(cpmc.MODIFIER, ''))=0
GO


