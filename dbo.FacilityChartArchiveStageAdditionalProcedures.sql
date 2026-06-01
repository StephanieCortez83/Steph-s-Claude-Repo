SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageAdditionalProcedures] (@ChartList udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT	dbo.FacilityChartArchiveChartAdditionalProcedures (CHART_ADDITIONAL_PROCEDURE_ID
																 , CHARGE_MASTER_ID
																 , QUANTITY
																 , MODIFIERS
																 , CHART_ID
																 , PROCEDURE_DATE
																 , PHYSICIAN_ID
																 , INSUFFICIENT_DOCUMENTATION_TO_BILL)
				SELECT	cap.CHART_ADDITIONAL_PROCEDURE_ID
					  , cap.CHARGE_MASTER_ID
					  , cap.QUANTITY
					  , cap.MODIFIERS
					  , cap.CHART_ID
					  , cap.PROCEDURE_DATE
					  , cap.PHYSICIAN_ID
					  , cap.INSUFFICIENT_DOCUMENTATION_TO_BILL
				FROM	CHART_ADDITIONAL_PROCEDURE cap WITH (NOLOCK)
				WHERE	cap.CLASS = 'PP'
						AND EXISTS (SELECT 1  FROM @ChartList  l WHERE cap.CHART_ID	 = l.x);
	END;
GO
