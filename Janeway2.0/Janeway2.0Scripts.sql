USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetServiceLevelCD].SQL

------------------------------------------------------------------------------------
-- 01) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetServiceLevelCD].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[GetServiceLevelCD] 
 	 @DateOfService DATE
	,@ServiceClassCD VARCHAR(10)
	,@ServiceGuidelineID INT
	,@ServiceTypeCD INT
	,@Cat1Rating INT
	,@Cat2Rating INT
	,@Cat3Rating INT
AS
BEGIN
	----------------
	-- Initially created by Mr. Burge CDBT-330
	-- Modified by pippin DACS-3201
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 1
		[SERVICE_LEVEL_CD]
	FROM	
		[dbo].[PHYSICIAN_SERVICE_LEVEL]
	WHERE	
		@DateOfService BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE
		AND PHYSICIAN_SERVICE_CLASS_CD = @ServiceClassCD
		AND PHYSICIAN_SERVICE_GUIDELINE_ID = @ServiceGuidelineID
		AND PHYSICIAN_SERVICE_TYPE_CD = @ServiceTypeCD
		AND CAT_1_RATING = @Cat1Rating
		AND CAT_2_RATING = @Cat2Rating
		AND CAT_3_RATING = @Cat3Rating;

END -- end procedure

GO

/*
testing:
select top 1000 * from PHYSICIAN_SERVICE_LEVEL
begin tran; -- testing
*/
-- End of 01) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetServiceLevelCD].SQL
GO

-- Start of 02) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetProcIDForServiceLevel].SQL

------------------------------------------------------------------------------------
-- 02) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetProcIDForServiceLevel].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[GetProcIDForServiceLevel] 
(
	@ServiceAgreemntID INT
	,@CriticalCare BIT
	,@serviceLevelCD INT
	,@PatientClassId INT
	,@DateOfService DATE
	,@HasProcedureRequiring25Modifier BIT
)
AS
BEGIN
	----------------
	-- Initially created by Mr. Burge CDBT-330
	-- Modified slightly by pippin DACS-3201
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DROP TABLE IF EXISTS #Services
		SELECT	 PHYSICIAN_SERVICE_PROC_ID
				,ISNULL(PROCEDURES, 0) Procedures
				,PREVENTATIVE_MEDICINE
				,SERVICE_AGREEMENT_ID
				,PATIENT_CLASS_ID
				,SERVICE_LEVEL_CD
		INTO #Services
		FROM PHYSICIAN_SERVICE_PROCEDURE
		WHERE	SERVICE_AGREEMENT_ID = @ServiceAgreemntID
				AND PATIENT_CLASS_ID = @PatientClassId
				AND CRITICAL_CARE = IIF(@CriticalCare = 1, 1, CRITICAL_CARE)
				AND SERVICE_LEVEL_CD = IIF(@CriticalCare = 0, @serviceLevelCD, SERVICE_LEVEL_CD)
				AND @DateOfService BETWEEN EFFECTIVE_DATE AND EXPIRATION_DATE

	IF EXISTS (
			SELECT 1
			FROM #Services
			WHERE	(PREVENTATIVE_MEDICINE <> 1 OR PREVENTATIVE_MEDICINE IS NULL) 
					AND PROCEDURES = @HasProcedureRequiring25Modifier
			)
	BEGIN
		SELECT TOP 1 PHYSICIAN_SERVICE_PROC_ID
		FROM #Services
			WHERE	(PREVENTATIVE_MEDICINE <> 1 OR PREVENTATIVE_MEDICINE IS NULL) 
					AND PROCEDURES = @HasProcedureRequiring25Modifier
	END
	ELSE
	BEGIN
		SELECT TOP 1 PHYSICIAN_SERVICE_PROC_ID
		FROM #Services
		WHERE PROCEDURES = 0
	END

END -- end procedure

GO

/*
testing:
select top 1000 * from PHYSICIAN_SERVICE_PROCEDURE
begin tran; -- testing

replaces the following C# inline SQL:
            sb.Append("SELECT PHYSICIAN_SERVICE_PROC_ID ");
            sb.Append("FROM PHYSICIAN_SERVICE_PROCEDURE ");
            sb.Append("WHERE ");
            sb.Append("     SERVICE_AGREEMENT_ID = " + saID.ToString());
            if (CriticalCare)
            {
                sb.Append(" AND CRITICAL_CARE = 1");
            }
            else
            {
                sb.Append(" AND SERVICE_LEVEL_CD = " + serviceLevelCD.ToString());
            }
            sb.Append(" AND isnull(PREVENTATIVE_MEDICINE,0) <> 1 ");
            sb.Append(" AND PATIENT_CLASS_ID = " + PatientClassID);
            sb.Append(" AND EFFECTIVE_DATE <= " + ConversionTools.ToDBShortDateY2K(dateOfService));
            sb.Append(" AND EXPIRATION_DATE >= " + ConversionTools.ToDBShortDateY2K(dateOfService));
            // 9-27-2010 JohnS: Include PROCEDURES column in SQL to retrieve correct level based on procedures requiring the 25 modifier
            if (hasProcedureRequiring25Modifier)
            {
                sb.Append(" AND PROCEDURES = 1");
            }
            else
            {
                sb.Append(" AND (PROCEDURES IS NULL OR PROCEDURES = 0) ");
            }

            sb.Append(andStr);

            sql = sb.ToString();
            cmd = RequestManager.DBManager.GetCommand(sql); //new SqlCommand(sql,RequestManager.DB);

            try
            {
                rdr = cmd.ExecuteReader();
                // If the object was found, fill in the object properties
                if (rdr.Read())
                {
                    result = GetInt(rdr, 0);
                }
            }
            finally
            {
                DisposeCmdAndRdr(cmd, rdr);
            }

            // 9-27-2010 JohnS: Until we get "with procedures" levels added for facilities where the SIM code is the same regardless of procedures
            //                  requiring the 25 modifier, get level not based on the PROCEDURES column if level not determined above
            if (result == -1 && hasProcedureRequiring25Modifier)
            {
                sb = new StringBuilder();
                sb.Append("SELECT PHYSICIAN_SERVICE_PROC_ID ");
                sb.Append("FROM PHYSICIAN_SERVICE_PROCEDURE ");
                sb.Append("WHERE ");
                sb.Append("     SERVICE_AGREEMENT_ID = " + saID.ToString());
                if (CriticalCare)
                {
                    sb.Append(" AND CRITICAL_CARE = 1");
                }
                else
                {
                    sb.Append(" AND SERVICE_LEVEL_CD = " + serviceLevelCD.ToString());
                }
                sb.Append(" AND EFFECTIVE_DATE <= " + ConversionTools.ToDBShortDateY2K(dateOfService));
                sb.Append(" AND EXPIRATION_DATE >= " + ConversionTools.ToDBShortDateY2K(dateOfService));
                sb.Append(" AND PATIENT_CLASS_ID = " + PatientClassID);
                sb.Append(" AND (PROCEDURES IS NULL OR PROCEDURES = 0) ");
                sb.Append(andStr);

                sql = sb.ToString();

*/
-- End of 02) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetProcIDForServiceLevel].SQL
GO

-- Start of 03) DACS-3201 - Create of Alter Stored Procedure - [dbo].[spGetEligibleServiceAgreementClinics].SQL

------------------------------------------------------------------------------------
-- 03) DACS-3201 - Create of Alter Stored Procedure - [dbo].[spGetEligibleServiceAgreementClinics].SQL
------------------------------------------------------------------------------------
GO

GO

GO

CREATE OR ALTER PROCEDURE [dbo].[spGetEligibleServiceAgreementClinics] 
(
	@ServiceAgreementId INT
	,@DateOfService DATETIME = NULL
)
AS
BEGIN
	----------------
	-- This update created by Mr. Burge CDBT-330
	-- Modified by pippin DACS-3201
	----------------

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT 
		[CLINIC_ID]
		,[DESCRIPTION]
	FROM 
		[dbo].[SERVICE_AGREEMENT_CLINIC]
	WHERE 
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND ( @DateOfService BETWEEN ISNULL(EFFECTIVE_DATE, @DateOfService) AND ISNULL(EXPIRATION_DATE, @DateOfService)	OR @DateOfService IS NULL )
	ORDER BY 
		[DESCRIPTION];

END -- end procedure

GO

/*
testing:
	--SELECT SERVICE_AGREEMENT_ID,count(1) FROM [SERVICE_AGREEMENT_CLINIC] group by SERVICE_AGREEMENT_ID order by count(1) desc
begin tran; -- testing

Replaces:
CREATE    PROCEDURE [dbo].[spGetEligibleServiceAgreementClinics]  
   @ServiceAgreementId int
 , @DateOfService datetime = null
  
AS
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN
   IF @DateOfService IS NULL
   BEGIN
		SELECT   
			[CLINIC_ID]  
			,[DESCRIPTION]  
		FROM   
			[dbo].[SERVICE_AGREEMENT_CLINIC] 
		WHERE  
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		ORDER BY   
			[DESCRIPTION];
	END
	ELSE
	BEGIN
		SELECT   
			[CLINIC_ID]  
			,[DESCRIPTION]  
		FROM   
			[dbo].[SERVICE_AGREEMENT_CLINIC]
		WHERE  
			[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
			AND 
			((EFFECTIVE_DATE IS NULL OR EFFECTIVE_DATE <= @DateOfService)
			AND
			(EXPIRATION_DATE IS NULL OR EXPIRATION_DATE >= @DateOfService))
			ORDER BY   
			[DESCRIPTION];
	END
END

*/
-- End of 03) DACS-3201 - Create of Alter Stored Procedure - [dbo].[spGetEligibleServiceAgreementClinics].SQL
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
