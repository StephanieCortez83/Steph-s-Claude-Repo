SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[rpt_MedStarProviderLocationMapping]
@Expired bit
WITH EXEC AS CALLER
AS
SELECT DISTINCT fp.LAST_NAME + ', ' + fp.FIRST_NAME [Physician Name],
                fp.FIRST_NAME,
                fp.LAST_NAME,
                fp.MIDDLE_NAME,
                fp.NAME_SUFFIX,
                fp.SECONDARY_EMPLOYEE_ID [Sched ID],
                mcl.LOCATION_CODE,
                mclm.SCHEDULING_LOCATION [Sched Location Code],
                mcl.[DESCRIPTION] [Sched Location Desc],
                fp.EMPLOYEE_IDENTIFIER [Echo],
                fp.UPIR_ID [NPI],
                sa.[DESCRIPTION] [Service Agreement],
                mclm.BILLING_AREA [Billing Area],
                mclm.LOCATION_CODE [Billing Location],
                ISNULL(fp.EXPIRATION_DATE, CONVERT(DATETIME, '12-31-2099')) [Expiration Date]
FROM ((FACILITY_PROFESSIONAL fp
		INNER JOIN MEDSTAR_CLINIC_LOC_MAP mclm ON (fp.FACILITY_PROF_ID = mclm.PROVIDER_ID))
		INNER JOIN SERVICE_AGREEMENT sa ON (mclm.SERVICE_AGREEMENT_ID = sa.SERVICE_AGREEMENT_ID))
		INNER JOIN MEDSTAR_CLINIC_LOCATION mcl ON (mcl.LOCATION_CODE = mclm.SCHEDULING_LOCATION)
WHERE fp.EFFECTIVE_DATE <= GETDATE() AND
      ISNULL(fp.EXPIRATION_DATE, CONVERT(DATETIME, '12-31-2099')) >= CASE @Expired
                                                                      WHEN 0 THEN GETDATE()
                                                                      ELSE fp.EFFECTIVE_DATE
                                                                      END
ORDER BY fp.LAST_NAME, fp.FIRST_NAME, mcl.LOCATION_CODE
GO
GRANT EXECUTE ON  [dbo].[rpt_MedStarProviderLocationMapping] TO [dbx_ExecuteReportProcs]
GO
