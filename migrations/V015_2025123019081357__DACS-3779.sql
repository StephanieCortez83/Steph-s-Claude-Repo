SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityProceduresWithQuantityByChartIdAndServiceAgreementIdAndUsageCodeAndTimeOfService]
   @ChartId             INT
  ,@ServiceAgreementId  INT
  ,@TimeOfService       DATETIME
  ,@UsageCode           INT = 3 -- ChargeMasterUsageCode.USAGE_CODE_FACILITY_PROCEDURE
AS
BEGIN
    SET NOCOUNT ON; 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
    --SET STATISTICS IO ON; -- Keep this for testing
	
	SELECT
		 CM.CHARGE_MASTER_ID
		,CM.CHARGE_MASTER_CATEGORY_ID
		,CM.DESCRIPTION
		,CM.LONG_DESCRIPTION
		,CM.CPT_CODE
		,CM.BILLING_CODE
		,CM.MODIFIER_REQUIRED
		,FPE.ICD9_CODE
		,FPE.ICD_10_CODE
		,CMC.DESCRIPTION
		,FPE.QUANTITY
		,FPE.MODIFIERS
		,FPE.ANESTHESIA_TYPE_ID
		,FPE.PROCEDURE_DATE
		,FPE.TRANSACTION_ID
		,FPE.PHYSICIAN_ID
		,FPE.INSUFFICIENT_DOCUMENTATION_TO_BILL
		,FPE.ADD_TO_PHYSICIAN_PROCEDURE
		,CM.MAX_QUANTITY
		,CM.ALLOW_NEGATIVE_UNITS_IND
		,FPE.ICD_10_PCS_CODE
		,CM.CHARGE_MASTER_DEPT_ID
		,CASE (SELECT TOP 1 1 FROM [CODER_QA_REPORT_EXCLUSION] EX WHERE EX.[SOURCE_RECORD_TABLE_NAME] = 'FACILITY_PROCEDURE_EVALUATION'
			AND [KEY_VALUE_1] = FPE.[CHART_ID] AND [KEY_VALUE_2] =  CAST(FPE.[FACILITY_PROCEDURE_ID] as varchar(15)) )
			WHEN 1 THEN 1 ELSE 0 END AS EXCLUDE_FROM_CODER_QA_REPORT 
		,CAST((SELECT COUNT(*) FROM [ICD_10_PCS_CPT_XREF] WHERE [CPT_CODE] COLLATE Latin1_General_CI_AI = CM.[CPT_CODE]) AS BIT) COLLECT_ICD10_PCS_IND
		,CAST(0 AS BIT) MODIFIERS_AVAILABLE
	FROM
		[CHARGE_MASTER] CM 
		LEFT OUTER JOIN [FACILITY_PROCEDURE_EVALUATION] FPE
					 ON CM.[CHARGE_MASTER_ID] = FPE.[FACILITY_PROCEDURE_ID]
		INNER JOIN [CHARGE_MASTER_DEPARTMENT] CMD
				ON CM.[CHARGE_MASTER_DEPT_ID] = cmd.[CHARGE_MASTER_DEPT_ID]
		INNER JOIN [CHARGE_MASTER_CATEGORY] CMC
				ON CM.[CHARGE_MASTER_CATEGORY_ID] = CMC.[CHARGE_MASTER_CATEGORY_ID]
	WHERE
		CM.[SERVICE_AGREEMENT_ID] = @ServiceAgreementId
		AND [CHART_ID] = @ChartId
		AND CM.[CHARGE_MASTER_USAGE_CODE] = @UsageCode
		AND FPE.[QUANTITY] <> 0
		AND @TimeOfService BETWEEN CM.[EFFECTIVE_DATE] AND CM.[EXPIRATION_DATE]
	ORDER BY
		 CMC.[DESCRIPTION]
		,CM.[DISPLAY_SEQ]
		,CM.[CPT_CODE] ASC;
END;
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-3779 SPROC variant within FacilityProcedureEvaluationListDAO.cs'))
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
			'ApplicationFeatureTypeCode'                                      						--NAME
		   ,'CAB_3779'                                                    							--KEY
		   ,14                                                                 						--VALUE
		   ,'CAB_3779'                                                    							--DISPLAY_NAME
		   ,'CAB_3779'                                                        						--SHORT_NAME
		   ,'Enable/Disables DACS-3779 SPROC variant within FacilityProcedureEvaluationListDAO.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 14)
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
			,14
		)
GO
