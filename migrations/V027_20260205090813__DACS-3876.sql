SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

DECLARE @CabName VARCHAR(20) = 'CAB_3876';
DECLARE @CabDesc VARCHAR(200) = 'Enable/Disables DACS-3876 SPROC variant within FacilityProcedureEvaluationListDAO.cs';
DECLARE @CabValue INT = 22;

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN (@CabDesc))
	INSERT INTO 
		[TYPE_CODE]
		(
			[NAME]
		   ,[KEY]
		   ,[VALUE]
		   ,[DISPLAY_NAME]
		   ,[SHORT_NAME]
		   ,[DESCRIPTION]
		)
		VALUES
		(
			'ApplicationFeatureTypeCode'    --NAME
		   ,@CabName						--KEY
		   ,@CabValue  						--VALUE
		   ,@CabName						--DISPLAY_NAME
		   ,@CabName  						--SHORT_NAME
		   ,@CabDesc 						--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists for [' + @CabName + '].  Action skipped.');
-- GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = @CabValue)
	INSERT INTO 
		[dbo].[ApplicationFeature]
		(
			 [DateTimeCreated]
			,[CreatedByUserProfileId]
			,[DateTimeLastUpdated]
			,[LastUpdatedByUserProfileId]
			,[ApplicationFeatureDomainObjectTypeCode]
			,[DomainObjectId]
			,[ApplicationFeatureTypeCode]
		)
	VALUES
		(
			 @dtCreated
			,@Uid
			,@dtCreated
			,@Uid
			,5
			,2147483647															--ALL
			,22
		)
ELSE
	PRINT('Application Feature already exists for [' + @CabName + '].  Action skipped.');
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl]
	 @ChartId INT
	,@ServiceAgreementId INT
	,@PatientClassId INT
	,@CategoryId INT = NULL
	,@DateOfService DATE = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
	
	IF @DateOfService IS NULL
		SET @DateOfService = GETDATE();
		
	IF @CategoryId IS NOT NULL
		SELECT
			 CM.[CHARGE_MASTER_ID]
			,CM.[CHARGE_MASTER_CATEGORY_ID]
			,CM.[DESCRIPTION]
			,CM.[LONG_DESCRIPTION]
			,CM.[CPT_CODE]
			,CM.[BILLING_CODE]
			,CM.[MODIFIER_REQUIRED]
			,FPE.[ICD9_CODE]
			,FPE.[ICD_10_CODE]
			,CMC.[DESCRIPTION]
			,FPE.[QUANTITY]
			,FPE.[MODIFIERS]
			,FPE.[ANESTHESIA_TYPE_ID]
			,FPE.[PROCEDURE_DATE]
			,FPE.[TRANSACTION_ID]
			,FPE.[PHYSICIAN_ID]
			,FPE.[INSUFFICIENT_DOCUMENTATION_TO_BILL]
			,FPE.[ADD_TO_PHYSICIAN_PROCEDURE]
			,CM.[MAX_QUANTITY]
			,CM.[ALLOW_NEGATIVE_UNITS_IND]
			,FPE.[ICD_10_PCS_CODE]
			,CM.[CHARGE_MASTER_DEPT_ID]
			,CASE
				(
					SELECT
						COUNT(*)
					FROM
						[CODER_QA_REPORT_EXCLUSION] ex
					WHERE
						ex.[SOURCE_RECORD_TABLE_NAME] = 'FACILITY_PROCEDURE_EVALUATION'
						AND [KEY_VALUE_1] = FPE.[CHART_ID]
						AND [KEY_VALUE_2] = CAST(FPE.[FACILITY_PROCEDURE_ID] AS varchar(15))
				)
				WHEN 0
					THEN 0
				ELSE 1
				END AS EXCLUDE_FROM_CODER_QA_REPORT
			,CAST
				(
					(
						SELECT
							COUNT(*)
						FROM
							[ICD_10_PCS_CPT_XREF]
						WHERE
							[CPT_CODE] COLLATE Latin1_General_CI_AI = CM.[CPT_CODE]
					) AS bit
				) COLLECT_ICD10_PCS_IND
			,CAST
				(
					(
						SELECT
							COUNT(*)
						FROM
							[CHARGE_MASTER_MODIFIER]
						WHERE
							[CHARGE_MASTER_ID] = CM.[CHARGE_MASTER_ID]
					) AS bit
				) MODIFIERS_AVAILABLE
		FROM
			[CHARGE_MASTER] CM
			LEFT OUTER JOIN [FACILITY_PROCEDURE_EVALUATION] FPE
						 ON CM.[CHARGE_MASTER_ID] = FPE.[FACILITY_PROCEDURE_ID] AND ([CHART_ID] = @ChartID OR [CHART_ID] = NULL)
			,[CHARGE_MASTER_CATEGORY] CMC
			,[CHARGE_MASTER_DEPARTMENT] CMD
		WHERE
			CM.[CHARGE_MASTER_CATEGORY_ID] = CMC.[CHARGE_MASTER_CATEGORY_ID]
			AND CM.[CHARGE_MASTER_DEPT_ID] = CMD.[CHARGE_MASTER_DEPT_ID]
			AND CM.[CHARGE_MASTER_USAGE_CODE] = 3
			AND ([INFUSION_CATEGORY] = 0 OR [INFUSION_CATEGORY] IS NULL)
			AND (CM.[PATIENT_CLASS_ID] = @PatientClassID OR CM.[PATIENT_CLASS_ID] = -1)
			AND @DateOfService BETWEEN CM.[EFFECTIVE_DATE] AND CM.[EXPIRATION_DATE]
			AND CM.[SERVICE_AGREEMENT_ID] = @ServiceAgreementID
			AND (/* CMD.OBSERVATION_IND IS NULL OR --no null values exist */ CMD.OBSERVATION_IND = 0)
			AND CMC.[CHARGE_MASTER_CATEGORY_ID] = @CategoryId
		ORDER BY
			 CMC.[DESCRIPTION]
			,CM.[DISPLAY_SEQ]
			,CM.[CPT_CODE] ASC;
	ELSE
		SELECT
			 CM.[CHARGE_MASTER_ID]
			,CM.[CHARGE_MASTER_CATEGORY_ID]
			,CM.[DESCRIPTION]
			,CM.[LONG_DESCRIPTION]
			,CM.[CPT_CODE]
			,CM.[BILLING_CODE]
			,CM.[MODIFIER_REQUIRED]
			,FPE.[ICD9_CODE]
			,FPE.[ICD_10_CODE]
			,CMC.[DESCRIPTION]
			,FPE.[QUANTITY]
			,FPE.[MODIFIERS]
			,FPE.[ANESTHESIA_TYPE_ID]
			,FPE.[PROCEDURE_DATE]
			,FPE.[TRANSACTION_ID]
			,FPE.[PHYSICIAN_ID]
			,FPE.[INSUFFICIENT_DOCUMENTATION_TO_BILL]
			,FPE.[ADD_TO_PHYSICIAN_PROCEDURE]
			,CM.[MAX_QUANTITY]
			,CM.[ALLOW_NEGATIVE_UNITS_IND]
			,FPE.[ICD_10_PCS_CODE]
			,CM.[CHARGE_MASTER_DEPT_ID]
			,CASE
				(
					SELECT
						COUNT(*)
					FROM
						[CODER_QA_REPORT_EXCLUSION] ex
					WHERE
						ex.[SOURCE_RECORD_TABLE_NAME] = 'FACILITY_PROCEDURE_EVALUATION'
						AND [KEY_VALUE_1] = FPE.[CHART_ID]
						AND [KEY_VALUE_2] = CAST(FPE.[FACILITY_PROCEDURE_ID] AS varchar(15))
				)
				WHEN 0
					THEN 0
				ELSE 1
				END AS EXCLUDE_FROM_CODER_QA_REPORT
			,CAST
				(
					(
						SELECT
							COUNT(*)
						FROM
							[ICD_10_PCS_CPT_XREF]
						WHERE
							[CPT_CODE] COLLATE Latin1_General_CI_AI = CM.[CPT_CODE]
					) AS bit
				) COLLECT_ICD10_PCS_IND
			,CAST
				(
					(
						SELECT
							COUNT(*)
						FROM
							[CHARGE_MASTER_MODIFIER]
						WHERE
							[CHARGE_MASTER_ID] = CM.[CHARGE_MASTER_ID]
					) AS bit
				) MODIFIERS_AVAILABLE
		FROM
			[CHARGE_MASTER] CM
			LEFT OUTER JOIN [FACILITY_PROCEDURE_EVALUATION] FPE
						 ON CM.[CHARGE_MASTER_ID] = FPE.[FACILITY_PROCEDURE_ID] AND ([CHART_ID] = @ChartID OR [CHART_ID] = NULL)
			,[CHARGE_MASTER_CATEGORY] CMC
			,[CHARGE_MASTER_DEPARTMENT] CMD
		WHERE
			CM.[CHARGE_MASTER_CATEGORY_ID] = CMC.[CHARGE_MASTER_CATEGORY_ID]
			AND CM.[CHARGE_MASTER_DEPT_ID] = CMD.[CHARGE_MASTER_DEPT_ID]
			AND CM.[CHARGE_MASTER_USAGE_CODE] = 3
			AND ([INFUSION_CATEGORY] = 0 OR [INFUSION_CATEGORY] IS NULL)
			AND (CM.[PATIENT_CLASS_ID] = @PatientClassID OR CM.[PATIENT_CLASS_ID] = -1)
			AND @DateOfService BETWEEN CM.[EFFECTIVE_DATE] AND CM.[EXPIRATION_DATE]
			AND CM.[SERVICE_AGREEMENT_ID] = @ServiceAgreementID
			AND (/* CMD.OBSERVATION_IND IS NULL OR --no null values exist */ CMD.OBSERVATION_IND = 0)
		ORDER BY
			 CMC.[DESCRIPTION]
			,CM.[DISPLAY_SEQ]
			,CM.[CPT_CODE] ASC;
	
END;
GO

DECLARE @exp VARCHAR(50) = (SELECT CAST(modify_date AS VARCHAR(50)) FROM sys.objects WHERE type = 'P' AND name = 'SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl');

IF OBJECT_ID('dbo.SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl', 'P') IS NOT NULL
	PRINT ('SPROC SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl last changed ' + @exp);
ELSE
	PRINT ('failed to create SPROC SelectChargeMasterFacilityProcedureEvaluationEtalBaseLoadDataByChartIdEtAl');
GO