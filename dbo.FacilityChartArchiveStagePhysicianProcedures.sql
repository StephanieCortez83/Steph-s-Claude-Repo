SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStagePhysicianProcedures] (@ChartList udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		INSERT	dbo.FacilityChartArchiveChartPhysicianProcedures (PHYSICIAN_PROCEDURE_ID
																, QUANTITY
																, MODIFIERS
																, CHART_ID
																, DIAGNOSIS_CODE
																, PROCEDURE_DATE
																, PHYSICIAN_ID
																, INSUFFICIENT_DOCUMENTATION_TO_BILL
																, DIAGNOSIS_CODE_ICD10)
				SELECT	ppe.PHYSICIAN_PROCEDURE_ID
					  , ppe.QUANTITY
					  , ppe.MODIFIERS
					  , ppe.CHART_ID
					  , ppe.ICD9_CODE	AS DIAGNOSIS_CODE
					  , ppe.PROCEDURE_DATE
					  , ppe.PHYSICIAN_ID
					  , ppe.INSUFFICIENT_DOCUMENTATION_TO_BILL
					  , ppe.ICD_10_CODE AS DIAGNOSIS_CODE_ICD10
				FROM	PHYSICIAN_PROCEDURE_EVALUATION ppe WITH (NOLOCK)
				WHERE	EXISTS (SELECT 1  FROM @ChartList  l WHERE ppe.CHART_ID	 = l.x);
	END;
GO
