SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE     PROCEDURE [dbo].[QualifyInsertIntoFacilityProcedureEvaluation] 
	 @ChartId INT
	,@FacilityProcedureId INT 
	,@CreatingUserProfileId INT
	,@Quantity INT
	,@AnesthesiaTypeId INT
	,@TransactionId INT
	,@PhysicianId INT
	,@InsufficientDocumentationToBill BIT
	,@AddToPhysicianProcedure BIT
	,@ProcedureDate DATETIME
	,@Modifiers VARCHAR(500)
	,@ICD10Code VARCHAR(300)
	,@ICD10PcsCodes VARCHAR(100)
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- updates:
	-- datetime check for @ProcedureDate DATETIME updated to handle < 1900 years	-- DACS-4367 - 20250403 - pippin
	-- ICD9_CODE field gets a default '' instead of leaving as NULL					-- DACS-4367 - 20250403 - pippin
	----------------


	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- validate parameters
	----------------
	IF @ChartId <= 0 OR @FacilityProcedureId <= 0 OR @CreatingUserProfileId <= 0
	BEGIN
		PRINT('One of the input parameters is invalid.  Exiting.')
		RETURN 0;
	END;

	IF EXISTS (SELECT TOP 1 1 FROM [FACILITY_PROCEDURE_EVALUATION] WHERE [CHART_ID] = @ChartId AND [FACILITY_PROCEDURE_ID] = @FacilityProcedureId)
	BEGIN
		PRINT('FK violation found for [' + CAST(@ChartId AS VARCHAR(32)) + ', ' + CAST(@FacilityProcedureId AS VARCHAR(32)) + '].  Exiting.')
		RETURN 0;
	END;

	DECLARE @creationDate DATETIME = GETDATE();
	DECLARE @procDateTest DATETIME = '01-01-1900';


	IF @ProcedureDate < @procDateTest
		SET @ProcedureDate = null

	INSERT INTO FACILITY_PROCEDURE_EVALUATION 
		(
			 [FACILITY_PROCEDURE_ID]
			,[CHART_ID]
			,[QUANTITY]
			,[MODIFIERS]
			,[ICD_10_CODE]
			,[ANESTHESIA_TYPE_ID]
			,[PROCEDURE_DATE]
			,[TRANSACTION_ID]
			,[ICD9_CODE]
			,[ICD_10_PCS_CODE]
            ,[PHYSICIAN_ID]
			,[INSUFFICIENT_DOCUMENTATION_TO_BILL]
			,[ADD_TO_PHYSICIAN_PROCEDURE]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
        ) 
		VALUES
		(
			 @FacilityProcedureId
			,@ChartId
			,@Quantity
			,@Modifiers
			,@ICD10Code
			,@AnesthesiaTypeId
			,@ProcedureDate
			,@TransactionId
			,'' -- hotfix change
			,@ICD10PcsCodes
			,@PhysicianId
			,@InsufficientDocumentationToBill
			,@AddToPhysicianProcedure
			,@creationDate
			,@CreatingUserProfileId
			,@creationDate
			,@CreatingUserProfileId
		)
	;

	RETURN 1;

	----------------
	-- Replaces the following ACS inline SQL:
	----------------
/*
replaces inline SQL:
"INSERT INTO FACILITY_PROCEDURE_EVALUATION ( "
                        + "FACILITY_PROCEDURE_ID, CHART_ID, QUANTITY, MODIFIERS, ICD9_CODE, ICD_10_CODE, ANESTHESIA_TYPE_ID, PROCEDURE_DATE, TRANSACTION_ID, ICD_10_PCS_CODE "
                        + ",PHYSICIAN_ID,INSUFFICIENT_DOCUMENTATION_TO_BILL,ADD_TO_PHYSICIAN_PROCEDURE,CREATION_DATE_TIME,CREATING_USER_PROFILE_ID,CHANGED_DATE_TIME,CHANGING_USER_PROFILE_ID"
                        + ") VALUES("
                        + li.FacilityProcedureID.ToString()
                        + "," + chartID.ToString()
                        + "," + li.Quantity.ToString()
                        + "," + ToDBString(li.Modifiers)
                        + "," + ToDBString(li.ICD9Code)
                        + "," + ToDBString(li.ICD10Code)
                        + "," + li.AnesthesiaTypeID.ToString()
                        + "," + ToDBDateTime(li.ProcedureDate)
                        + "," + transID.ToString()
                        + "," + ToDBString(li.ICD10PcsCodes)
                        + "," + li.PhysicianID.ToString()
                        + "," + ToDBBoolean(li.InsufficientDocToBill)
                        + "," + ToDBBoolean(li.AddToPhysicianProcedure)
                        + "," + ToDBDate(stamp.CreationDateTime)
                        + "," + stamp.CreatingUserProfileID
                        + "," + ToDBDateTime(stamp.ChangedDateTime)
                        + "," + stamp.ChangingUserProfileID
                        + ")";
from \CCSBusinessObjects\DAO\Facility\FacilityProcedureEvaluationListDAO.cs method Update99292ForChart(int chartID, FacilityProcedureEvaluationListItem li)
*/	
END -- end procedure

GO
