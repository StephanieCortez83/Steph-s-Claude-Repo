SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[FacilityChartArchiveStageChargeMaster]
AS
	BEGIN
		SET NOCOUNT ON;

		WITH cmId AS (
					 SELECT fp.FACILITY_PROCEDURE_ID CHARGE_MASTER_ID
					 FROM	dbo.FacilityChartArchiveChartFacilityProcedures fp 
					 UNION
					 SELECT ppe.PHYSICIAN_PROCEDURE_ID
					 FROM	dbo.FacilityChartArchiveChartPhysicianProcedures ppe
					 UNION
					 SELECT ap.CHARGE_MASTER_ID
					 FROM	dbo.FacilityChartArchiveChartAdditionalProcedures ap
					 UNION
					 SELECT ir.CHARGE_MASTER_ID
					 FROM	dbo.FacilityChartArchiveChartInfusionResults ir
					 )
		INSERT	dbo.FacilityChartArchiveChargeMaster (CHARGE_MASTER_ID
													, DESCRIPTION
													, CPT_CODE
													, BILLING_CODE
													, ALIAS_BILLING_CODE
													, ICD9_CODE
													, CHARGE_MASTER_USAGE_CODE
													, FACILITY_DEPARTMENT_CODE
													, CHARGE_MASTER_DEPARTMENT_NAME)
				SELECT	cm.CHARGE_MASTER_ID
					  , cm.DESCRIPTION
					  , cm.CPT_CODE
					  , cm.BILLING_CODE
					  , cm.ALIAS_BILLING_CODE
					  , cm.ICD9_CODE
					  , cm.CHARGE_MASTER_USAGE_CODE
					  , cmd.FACILITY_DEPARTMENT_CODE
					  , cmd.NAME CHARGE_MASTER_DEPARTMENT_NAME
				FROM	dbo.CHARGE_MASTER					cm WITH (NOLOCK)
						INNER JOIN CHARGE_MASTER_DEPARTMENT cmd WITH (NOLOCK)
							ON cm.CHARGE_MASTER_DEPT_ID = cmd.CHARGE_MASTER_DEPT_ID
				WHERE	EXISTS (SELECT	1
								FROM	cmId x
								WHERE	x.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID)
						AND NOT EXISTS (SELECT	1
										FROM	FacilityChartArchiveChargeMaster x
										WHERE	x.CHARGE_MASTER_ID = cm.CHARGE_MASTER_ID);
	END;
GO
