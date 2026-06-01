SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertPhysicianProcedureEvaluation]   
	 @PhysicianProcedureId INT
	,@ChartId INT
	,@Quantity INT
	,@Modifiers VARCHAR(500)
	,@Icd10Code VARCHAR(300)
	,@ProcedureDate DATETIME
	,@PhysicianId INT
	,@InsufficientDocumentationToBill BIT 
	,@AddToFacilityProcedure BIT
	,@ChangingUserProfileId INT
WITH EXEC AS CALLER AS      
BEGIN  
	DECLARE @creationDate DATETIME = GETDATE();

	IF NOT EXISTS (SELECT TOP 1 1 FROM [PHYSICIAN_PROCEDURE_EVALUATION] WHERE [PHYSICIAN_PROCEDURE_ID]=@PhysicianProcedureId AND [CHART_ID]=@ChartId) 
		INSERT INTO [dbo].[PHYSICIAN_PROCEDURE_EVALUATION]
		(
			 [PHYSICIAN_PROCEDURE_ID]
			,[CHART_ID]
			,[QUANTITY]
			,[MODIFIERS]
			,[ICD_10_CODE]
			,[PROCEDURE_DATE]
			,[PHYSICIAN_ID]
			,[INSUFFICIENT_DOCUMENTATION_TO_BILL]
			,[ADD_TO_FACILITY_PROCEDURE]
			,[CREATION_DATE_TIME]
			,[CREATING_USER_PROFILE_ID]
			,[CHANGED_DATE_TIME]
			,[CHANGING_USER_PROFILE_ID]
		)
		VALUES
		(
			 @PhysicianProcedureId
			,@ChartId
			,@Quantity
			,@Modifiers
			,@Icd10Code
			,@ProcedureDate
			,@PhysicianId
			,@InsufficientDocumentationToBill
			,@AddToFacilityProcedure
			,@creationDate
			,@ChangingUserProfileId
			,@creationDate
			,@ChangingUserProfileId
		);

/*
replaces the following inline C# SQL:
	sql = "INSERT INTO PHYSICIAN_PROCEDURE_EVALUATION ( "
		+ "PHYSICIAN_PROCEDURE_ID, CHART_ID, QUANTITY, MODIFIERS, ICD9_CODE, ICD_10_CODE, PROCEDURE_DATE "
		+ ",PHYSICIAN_ID,INSUFFICIENT_DOCUMENTATION_TO_BILL,ADD_TO_FACILITY_PROCEDURE,CREATION_DATE_TIME,CREATING_USER_PROFILE_ID,CHANGED_DATE_TIME,CHANGING_USER_PROFILE_ID"
		+ ") VALUES("
		+ li.PhysicianProcedureID.ToString()
		+ "," + aChart.ChartID.ToString()
		+ "," + li.Quantity.ToString()
		+ "," + ToDBString(li.Modifiers)
		+ "," + ToDBString(li.ICD9Code)
		+ "," + ToDBString(li.ICD10Code)
		+ "," + ToDBDateTime(li.ProcedureDate)
		+ "," + (li.PhysicianID > 0 ? li.PhysicianID : defaultProviderID).ToString()
		+ "," + ToDBBoolean(li.InsufficientDocToBill)
		+ "," + ToDBBoolean(li.AddToFacilityProcedure)
		+ "," + ToDBDate(stamp.CreationDateTime)
		+ "," + stamp.CreatingUserProfileID
		+ "," + ToDBDate(stamp.ChangedDateTime)
		+ "," + stamp.ChangingUserProfileID
		+ ")";END -- end SPROC
*/

END -- end SPROC

GO
