SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertIntoFacilityProcedureEvaluationPackageEventItemsByChartIdEtal] 
	 @ChartId INT
	,@CreatingUserProfileId INT
	,@ChargePackageTypeId INT
WITH EXEC AS CALLER AS
BEGIN
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- validate parameters
	----------------
	IF @ChartId <= 0 OR @CreatingUserProfileId <= 0 OR @ChargePackageTypeId <= 0
	BEGIN
		PRINT('One of the input parameters is invalid.  Exiting.')
		RETURN 0;
	END;

	INSERT INTO FACILITY_PROCEDURE_EVALUATION 
		(
			 [FACILITY_PROCEDURE_ID]
			,[CHART_ID]
			,[QUANTITY]
			,[PROCEDURE_DATE]
			,[TRANSACTION_ID]
			,[PHYSICIAN_ID]
			,[INSUFFICIENT_DOCUMENTATION_TO_BILL]
			,[ADD_TO_PHYSICIAN_PROCEDURE]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
        )
	SELECT 
		cpi.[CHARGE_MASTER_ID] FACILITY_PROCEDURE_ID,
		fpe.[CHART_ID],
		ISNULL(NULLIF(cpi.[UNITS], 0), fpe.[QUANTITY]) QUANTITY,
		fpe.[PROCEDURE_DATE],
		fpe.[TRANSACTION_ID],
		fpe.[PHYSICIAN_ID],
		CAST(0 AS BIT) INSUFFICIENT_DOCUMENTATION_TO_BILL,
		CAST(0 AS BIT) ADD_TO_PHYSICIAN_PROCEDURE,
		GETDATE() CREATION_DATE_TIME,
		@CreatingUserProfileId CREATING_USER_PROFILE_ID,
		GETDATE() CHANGED_DATE_TIME,
		@CreatingUserProfileId CHANGING_USER_PROFILE_ID
	FROM 
		[FACILITY_PROCEDURE_EVALUATION] fpe
		INNER JOIN [CHART] c ON c.CHART_ID = fpe.CHART_ID
		INNER JOIN [CHARGE_PACKAGE_ITEM] cpi ON cpi.[PACKAGE_EVENT_ID] = fpe.FACILITY_PROCEDURE_ID
	WHERE 
		fpe.[CHART_ID] = @ChartId
		AND cpi.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
		AND [PACKAGE_TYPE_CD] = @ChargePackageTypeId
		AND cpi.[SUPPLY_IND] = 0
		AND DATEADD(DAY, DATEDIFF(DAY, 0, c.[TIME_OF_SERVICE]), 0) BETWEEN cpi.[EFFECTIVE_DATE] AND ISNULL(cpi.[EXPIRATION_DATE], GETDATE())
		AND NOT EXISTS 
			(
				SELECT TOP 1 1
				FROM 
					[FACILITY_PROCEDURE_EVALUATION]
				WHERE 
					[CHART_ID] = @ChartId
					AND [FACILITY_PROCEDURE_ID] = cpi.[CHARGE_MASTER_ID]
			)
	;	

	RETURN 1;
	
	----------------
	-- Replaces the following ACS inline SQL:
	----------------
/*
const string sql = "INSERT INTO FACILITY_PROCEDURE_EVALUATION ("
                 + "FACILITY_PROCEDURE_ID, CHART_ID, QUANTITY, PROCEDURE_DATE, TRANSACTION_ID, "
                 + "PHYSICIAN_ID,INSUFFICIENT_DOCUMENTATION_TO_BILL, ADD_TO_PHYSICIAN_PROCEDURE,CREATION_DATE_TIME,CREATING_USER_PROFILE_ID,CHANGED_DATE_TIME,CHANGING_USER_PROFILE_ID"
                 + ") "
                 + "SELECT cpi.CHARGE_MASTER_ID FACILITY_PROCEDURE_ID, "
                 + "    fpe.CHART_ID, "
                 + "    ISNULL(NULLIF(cpi.UNITS, 0), fpe.QUANTITY) QUANTITY, "
                 + "    fpe.PROCEDURE_DATE, "
                 + "    fpe.TRANSACTION_ID, "
                 + "    fpe.PHYSICIAN_ID, "
                 + "    CAST(0 AS BIT) INSUFFICIENT_DOCUMENTATION_TO_BILL, "
                 + "    CAST(0 AS BIT) ADD_TO_PHYSICIAN_PROCEDURE, "
                 + "    GETDATE() CREATION_DATE_TIME, "
                 + "    @CreatingUserID CREATING_USER_PROFILE_ID, "
                 + "    GETDATE() CHANGED_DATE_TIME, "
                 + "    @CreatingUserID CHANGING_USER_PROFILE_ID "
                 + "FROM FACILITY_PROCEDURE_EVALUATION fpe WITH (NOLOCK) "
				 + "INNER JOIN CHART c WITH (NOLOCK) ON c.CHART_ID = fpe.CHART_ID "
				 + "INNER JOIN CHARGE_PACKAGE_ITEM cpi WITH (NOLOCK) ON cpi.PACKAGE_EVENT_ID = fpe.FACILITY_PROCEDURE_ID "
				 + "WHERE fpe.CHART_ID = @ChartID "
                 + "    AND cpi.SERVICE_AGREEMENT_ID = c.SERVICE_AGREEMENT_ID "
                 + "    AND PACKAGE_TYPE_CD = @ChargePackageType"
                 + "    AND cpi.SUPPLY_IND = 0 "
                 + "    AND DATEADD(DAY, DATEDIFF(DAY, 0, c.TIME_OF_SERVICE), 0) BETWEEN cpi.EFFECTIVE_DATE AND ISNULL(cpi.EXPIRATION_DATE, GETDATE()) "
                 + "    AND NOT EXISTS ( "
                 + "        SELECT * "
                 + "        FROM FACILITY_PROCEDURE_EVALUATION WITH (NOLOCK) "
				 + "        WHERE CHART_ID = fpe.CHART_ID "
                 + "            AND FACILITY_PROCEDURE_ID = cpi.CHARGE_MASTER_ID "
                 + "        )";
from \CCSBusinessObjects\DAO\Facility\FacilityProcedureEvaluationListDAO.cs method private void AddPackageEventItems(int chartId)
*/	
END -- end procedure

GO
