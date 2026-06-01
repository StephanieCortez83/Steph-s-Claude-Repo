------------------------------------------------------------------------------------
-- 01) DACS-3581 - Create or Alter function - [dbo].[udfMIPSSelectPresentProcedureCodesByChartId].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- drop type 
DROP TYPE IF EXISTS t2xString32;

CREATE TYPE t2xString32 AS TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
) --WITH ( MEMORY_OPTIMIZED = ON )

GO	
------------------------------------------------------------------------------------

CREATE or Alter FUNCTION [dbo].[udfMIPSSelectPresentProcedureCodesByChartId]
(
	  @ChartId INT
	 ,@ServiceAgreementId INT
)
RETURNS @returnResults TABLE
(
	 Value1 VARCHAR(32)
	,Value2 VARCHAR(32)
)
AS
BEGIN
	----------------
	-- Present Procedure List 
	----------------
	INSERT INTO 
		@returnResults
	SELECT 
		 cm.[CPT_CODE] AS Value1
		,ppe.[MODIFIERS]  AS Value2
	FROM 
		[PHYSICIAN_PROCEDURE_EVALUATION] ppe
		INNER JOIN [CHARGE_MASTER] cm
			ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID]
				AND ppe.[CHART_ID] = @ChartId;
	 
	DECLARE @PSP_CPT varchar(50);
	DECLARE @PSP_MODIFIERS varchar(250);
	
	SELECT TOP 1 
		 @PSP_CPT = [CPT_CODE]
		,@PSP_MODIFIERS = [MODIFIER]
	FROM 
		[PHYSICIAN_SERVICE_PROCEDURE] p
		INNER JOIN [CHART] c ON p.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
	WHERE 
		p.[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND p.[PHYSICIAN_SERVICE_PROC_ID] = 
		CASE 
			WHEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID] > 0
				THEN c.[OVERRIDE_PHYSICIAN_SERVICE_PROC_ID]
			ELSE 
				c.[PHYSICIAN_SERVICE_PROC_ID]
        END;
	 
	IF @PSP_CPT IS NOT NULL AND LEN(@PSP_CPT) = 5 
		INSERT INTO @returnResults ([Value1]) VALUES (@PSP_CPT);

	IF @PSP_MODIFIERS IS NOT NULL AND LEN(@PSP_MODIFIERS) >= 2 
		INSERT INTO @returnResults ([Value2]) VALUES (@PSP_MODIFIERS);
	 
	-- IF @ShowDebug <> 0 SELECT * FROM @returnResults; -- testing
	RETURN;
 END; -- end function

GO
