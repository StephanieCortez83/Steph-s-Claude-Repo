SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROC [dbo].[SelectChargeMasterIdByServiceAgreementIdAndDateOfServiceAndBillingCodeEtAl]  
	 @ServiceAgreementId INT
	,@DateOfService DATE
	,@BillingCode VARCHAR(20)
	,@PatientClassId INT = NULL
	,@ChargeMasterUsageCode INT = NULL
AS  
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @ServiceAgreementId IS NULL OR @ServiceAgreementId <= 0
		RETURN;

	IF @DateOfService IS NULL OR @DateOfService < '01-01-1990'
		SET @DateOfService = GETDATE();

	IF @PatientClassId IS NULL AND @ChargeMasterUsageCode IS NULL
	BEGIN
		SELECT TOP 1
			[CHARGE_MASTER_ID]
		FROM 
			[CHARGE_MASTER]
		WHERE
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
			AND @DateOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]
			AND [BILLING_CODE] = @BillingCode;
		RETURN;
	END;

	DROP TABLE IF EXISTS #TmpResults;

	SELECT
		 [CHARGE_MASTER_ID]
		,[PATIENT_CLASS_ID]
		,[CHARGE_MASTER_USAGE_CODE]
	INTO 
		#TmpResults
	FROM 
		[CHARGE_MASTER]
	WHERE
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND @DateOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]
		AND [BILLING_CODE] = @BillingCode;

	IF @PatientClassId IS NOT NULL AND @ChargeMasterUsageCode IS NULL
	BEGIN 
		SELECT TOP 1 
			[CHARGE_MASTER_ID]
		FROM 
			#TmpResults
		WHERE 
			[PATIENT_CLASS_ID] = @PatientClassId OR [PATIENT_CLASS_ID] = -1;
		RETURN;
	END;
	
	IF @PatientClassId IS NOT NULL AND @ChargeMasterUsageCode IS NOT NULL
	BEGIN 
		SELECT TOP 1 
			[CHARGE_MASTER_ID]
		FROM 
			#TmpResults
		WHERE 
			([PATIENT_CLASS_ID] = @PatientClassId OR [PATIENT_CLASS_ID] = -1)
			AND CHARGE_MASTER_USAGE_CODE = @ChargeMasterUsageCode;
		RETURN;
	END;

/*
replaces the following inline SQL:
\CCSBusinessObjects\DAO\ChargeMaster\ChargeMasterDAO.cs
~line 460:
        public int FindChargeMasterID(int serviceAgreementID, String departmentID, String billingCode, DateTime asOfDate)
        {
            string sql;
            SqlCommand cmd = null;
            SqlDataReader rdr = null;
            ChargeMasterItem obj = null;
            int chargeMasterID = -1;

            sql = "SELECT " + m_Fields
                + " FROM CHARGE_MASTER "
                + " WHERE  "
                + " CHARGE_MASTER.EFFECTIVE_DATE <= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.EXPIRATION_DATE >= " + ToDBShortDate(asOfDate)
                + " AND SERVICE_AGREEMENT_ID = " + serviceAgreementID
                + " AND CHARGE_MASTER.CHARGE_MASTER_DEPT_ID = " + departmentID
                + " AND CHARGE_MASTER.BILLING_CODE = " + ToDBString(billingCode)
                ;

            cmd = GetCommand(sql); 

~line 576:
        public int FindChargeMasterID(int serviceAgreementID, String billingCode, DateTime asOfDate)
        {
            string sql;
            SqlCommand cmd = null;
            SqlDataReader rdr = null;
            ChargeMasterItem obj = null;
            int chargeMasterID = -1;
            
            sql = "SELECT " + m_Fields
                + " FROM CHARGE_MASTER "
                + " WHERE  "
                + "     SERVICE_AGREEMENT_ID = " + serviceAgreementID
                + " AND CHARGE_MASTER.EFFECTIVE_DATE <= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.EXPIRATION_DATE >= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.BILLING_CODE = " + ToDBString(billingCode)
                ;

~line 615:
        public int FindChargeMasterID(int serviceAgreementID, String billingCode, int patientClassID, DateTime asOfDate)
        {
            string sql;
            SqlCommand cmd = null;
            SqlDataReader rdr = null;
            ChargeMasterItem obj = null;
            int chargeMasterID = -1;

            sql = "SELECT " + m_Fields
                + " FROM CHARGE_MASTER "
                + " WHERE  "
                + "     SERVICE_AGREEMENT_ID = " + serviceAgreementID
                + " AND CHARGE_MASTER.EFFECTIVE_DATE <= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.EXPIRATION_DATE >= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.BILLING_CODE = " + ToDBString(billingCode)
                + " AND (CHARGE_MASTER.PATIENT_CLASS_ID = " + patientClassID + " OR CHARGE_MASTER.PATIENT_CLASS_ID = -1)";
            ;

~line 654:
        public int FindChargeMasterID(int serviceAgreementID, String billingCode, int patientClassID, int chargeMasterUsageCode, DateTime asOfDate)
        {
            string sql;
            SqlCommand cmd = null;
            SqlDataReader rdr = null;
            ChargeMasterItem obj = null;
            int chargeMasterID = -1;

            sql = "SELECT " + m_Fields
                + " FROM CHARGE_MASTER "
                + " WHERE  "
                + "     SERVICE_AGREEMENT_ID = " + serviceAgreementID
                + " AND CHARGE_MASTER.EFFECTIVE_DATE <= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.EXPIRATION_DATE >= " + ToDBShortDate(asOfDate)
                + " AND CHARGE_MASTER.BILLING_CODE = " + ToDBString(billingCode)
                + " AND CHARGE_MASTER.CHARGE_MASTER_USAGE_CODE = " + chargeMasterUsageCode
                + " AND (CHARGE_MASTER.PATIENT_CLASS_ID = " + patientClassID + " OR CHARGE_MASTER.PATIENT_CLASS_ID = -1)";

*/
END -- end SPROC

GO
