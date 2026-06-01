SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveGetFacilityLOS] (@ChartList udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		SELECT	fl.CHART_ID
			  , fl.FACILITY_LEVEL_ID
			  , fl.MODIFIER
			  , fl.DESCRIPTION
			  , fl.CPT_CODE
			  , fl.BILLING_CODE
			  , fl.DEPARTMENT
			  , fl.QUANTITY
		FROM	dbo.FacilityChartArchiveChartFacilityLOS fl
		WHERE	EXISTS (SELECT 1  FROM @ChartList  x WHERE x.x =  fl.CHART_ID);
	END;
GO
