------------------------------------------------------------------------------------
-- 02) DACS-3201 - Create of Alter Stored Procedure - [dbo].[GetProcIDForServiceLevel].SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
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
rollback tran; -- testing
commit tran; -- testing

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