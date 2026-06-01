SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveGetChartInfusionResults] (@ChartList udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		SELECT	i.CHART_INFUSION_RESULT_ID
			  , i.CHART_ID
			  , i.UNITS
			  , i.CHARGE_MASTER_ID
			  , cm.CPT_CODE
			  , i.MODIFIERS
			  , cm.DESCRIPTION
			  , i.DATE_OF_SERVICE
		FROM	dbo.FacilityChartArchiveChartInfusionResults   i
				LEFT JOIN dbo.FacilityChartArchiveChargeMaster cm
					ON cm.CHARGE_MASTER_ID = i.CHARGE_MASTER_ID
		WHERE	EXISTS (SELECT 1  FROM @ChartList  x WHERE x.x =  i.CHART_ID);
	END;
GO
