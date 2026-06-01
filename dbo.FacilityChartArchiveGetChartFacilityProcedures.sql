SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveGetChartFacilityProcedures] (@ChartList udt_int READONLY)
AS
	BEGIN
		SET NOCOUNT ON;

		SELECT	fp.QUANTITY
			  , fp.MODIFIERS
			  , cm.DESCRIPTION
			  , cm.CPT_CODE
			  , cm.BILLING_CODE
			  , cm.ALIAS_BILLING_CODE
			  , cm.ICD9_CODE
			  , fp.CHART_ID
			  , fp.FACILITY_PROCEDURE_ID CHARGE_MASTER_ID
			  , fp.PROCEDURE_DATE
			  , fp.PHYSICIAN_ID
			  , fp.INSUFFICIENT_DOCUMENTATION_TO_BILL
			  , fp.DIAGNOSIS_CODE
			  , fp.DIAGNOSIS_CODE_ICD10
			  , fp.ICD_10_PCS_CODE
		FROM	dbo.FacilityChartArchiveChartFacilityProcedures fp
				LEFT JOIN dbo.FacilityChartArchiveChargeMaster	cm
					ON cm.CHARGE_MASTER_ID = fp.FACILITY_PROCEDURE_ID
		WHERE	EXISTS (SELECT 1  FROM @ChartList  x WHERE x.x =  fp.CHART_ID);
	END;
GO
