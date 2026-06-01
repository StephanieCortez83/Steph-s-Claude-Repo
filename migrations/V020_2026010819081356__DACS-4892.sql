SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4892 SPROC variant within PhysicianProcedureEvaluationListDAO.cs'))
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
			'ApplicationFeatureTypeCode'                                      							--NAME
		   ,'CAB_4892'                                                    								--KEY
		   ,18                                                                							--VALUE
		   ,'CAB_4892'                                                    								--DISPLAY_NAME
		   ,'CAB_4892'                                                        							--SHORT_NAME
		   ,'Enable/Disables DACS-4892 SPROC variant within PhysicianProcedureEvaluationListDAO.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 18)
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
			,18
		)
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianProcedureEvaluationAvailableByChartIdAndCategoryId]
	 @ChartId INT
	,@CategoryId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 
	
	--------------------------------
	-- at present, only 22 of the 2500 SAs on Legacy Prod use Collected Payor options.
	-- to improve performance, cases are allowed to make the majority more efficient while retaining functionality for payor classes.
	--------------------------------
	
	DECLARE @said INT = (SELECT TOP 1 [SERVICE_AGREEMENT_ID] FROM [CHART] WHERE [CHART_ID] = @ChartId);
	DECLARE @collectPayor INT = (SELECT TOP 1 1 FROM [SERVICE_AGREEMENT] WHERE [SERVICE_AGREEMENT_ID] = @said AND NOT([COLLECT_PAYOR] IS NULL OR [COLLECT_PAYOR] = 'N'));
	
	IF @said IS NULL
		RETURN;
		
	IF @collectPayor IS NULL
	BEGIN 
		IF @CategoryId > 0
			SELECT TOP 1 1
			FROM
				[CHARGE_MASTER] cm
				LEFT OUTER JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe 
							 ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID] AND (ppe.[CHART_ID]=@ChartId OR ppe.[CHART_ID] is null)
				LEFT OUTER JOIN [CHART] c
							 ON c.[CHART_ID] = @ChartId AND c.[TIME_OF_SERVICE] BETWEEN cm.[EFFECTIVE_DATE] AND cm.[EXPIRATION_DATE]
			WHERE
				cm.[SERVICE_AGREEMENT_ID] = @said
				AND cm.[CHARGE_MASTER_USAGE_CODE] = 5 -- Physician Procedure
				AND (cm.[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID] OR CM.[PATIENT_CLASS_ID] = -1)
				AND cm.[CHARGE_MASTER_CATEGORY_ID] = @CategoryId;
		ELSE
			SELECT TOP 1 1
			FROM
				[CHARGE_MASTER] cm
				LEFT OUTER JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe 
							 ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID] AND (ppe.[CHART_ID]=@ChartId OR ppe.[CHART_ID] is null)
				LEFT OUTER JOIN [CHART] c
							 ON c.[CHART_ID] = @ChartId AND c.[TIME_OF_SERVICE] BETWEEN cm.[EFFECTIVE_DATE] AND cm.[EXPIRATION_DATE]
			WHERE
				cm.[SERVICE_AGREEMENT_ID] = @said
				AND cm.[CHARGE_MASTER_USAGE_CODE] = 5 -- Physician Procedure
				AND (cm.[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID] OR CM.[PATIENT_CLASS_ID] = -1);

		PRINT('NON Collect Payor Type')
		RETURN;
	END	

	IF @CategoryId > 0
		SELECT TOP 1 1
		FROM
			[CHARGE_MASTER] cm
			LEFT OUTER JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe 
						 ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID] AND (ppe.[CHART_ID]=@ChartId OR ppe.[CHART_ID] is null)
			LEFT OUTER JOIN [CHART] c
						 ON c.[CHART_ID] = @ChartId AND c.[TIME_OF_SERVICE] BETWEEN cm.[EFFECTIVE_DATE] AND cm.[EXPIRATION_DATE]
			LEFT OUTER JOIN [SERVICE_AGREEMENT] sa
						 ON sa.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
			LEFT OUTER JOIN [FACILITY_FINANCIAL_CLASS] ffc
						 ON ffc.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID] AND ffc.[FINANCIAL_CLASS_CD] = c.[FINANCIAL_CLASS_CD]
			LEFT OUTER JOIN [CHART_PAYOR] cp
						 ON cp.[CHART_ID] = c.[CHART_ID]
			LEFT OUTER JOIN [SERVICE_AGREEMENT_PAYOR] sap
						 ON sap.[SERVICE_AGREEMENT_PAYOR_ID] = cp.[SERVICE_AGREEMENT_PAYOR_ID]
		WHERE
			cm.[SERVICE_AGREEMENT_ID] = @said
			AND cm.[CHARGE_MASTER_USAGE_CODE] = 5 -- Physician Procedure
			AND (cm.[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID] OR CM.[PATIENT_CLASS_ID] = -1)
			AND (
				ISNULL(sa.[USE_PAYOR_CLASS_IND], 0) = 0
				OR (NULLIF(sap.[PAYOR_CLASS_ID], -1) IS NULL AND NULLIF(ffc.[PAYOR_CLASS_ID], -1) IS NULL)
				OR cm.[CPT_CODE] NOT IN 
				(
					SELECT
						[CODE_VALUE]
					FROM
						[CODE_LIST_USAGE] u
						JOIN [CODE_LIST] l ON l.[CODE_LIST_ID] = u.[CODE_LIST_ID]
						JOIN [CODE_LIST_ITEM] i ON i.[CODE_LIST_ID] = l.[CODE_LIST_ID]
						JOIN [PAYOR_CLASS] p ON p.[PAYOR_CLASS_ID] = u.[ASSIGNMENT_ID]
						WHERE u.[CODE_LIST_USAGE_CODE] = 'PayorClassCPTExclusion'
						AND p.[PAYOR_CLASS_ID] = ISNULL(NULLIF(sap.[PAYOR_CLASS_ID], -1), ffc.[PAYOR_CLASS_ID])
						AND DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) BETWEEN u.[EFFECTIVE_DTTM] AND u.[EXPIRATION_DTTM]
						AND DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) BETWEEN i.[EFFECTIVE_DTTM] AND i.[EXPIRATION_DTTM]
				)
			)
			AND cm.[CHARGE_MASTER_CATEGORY_ID] = @CategoryId;
	ELSE
		SELECT TOP 1 1
		FROM
			[CHARGE_MASTER] cm
			LEFT OUTER JOIN [PHYSICIAN_PROCEDURE_EVALUATION] ppe 
						 ON cm.[CHARGE_MASTER_ID] = ppe.[PHYSICIAN_PROCEDURE_ID] AND (ppe.[CHART_ID]=@ChartId OR ppe.[CHART_ID] is null)
			LEFT OUTER JOIN [CHART] c
						 ON c.[CHART_ID] = @ChartId AND c.[TIME_OF_SERVICE] BETWEEN cm.[EFFECTIVE_DATE] AND cm.[EXPIRATION_DATE]
			LEFT OUTER JOIN [SERVICE_AGREEMENT] sa
						 ON sa.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID]
			LEFT OUTER JOIN [FACILITY_FINANCIAL_CLASS] ffc
						 ON ffc.[SERVICE_AGREEMENT_ID] = c.[SERVICE_AGREEMENT_ID] AND ffc.[FINANCIAL_CLASS_CD] = c.[FINANCIAL_CLASS_CD]
			LEFT OUTER JOIN [CHART_PAYOR] cp
						 ON cp.[CHART_ID] = c.[CHART_ID]
			LEFT OUTER JOIN [SERVICE_AGREEMENT_PAYOR] sap
						 ON sap.[SERVICE_AGREEMENT_PAYOR_ID] = cp.[SERVICE_AGREEMENT_PAYOR_ID]
		WHERE
			cm.[SERVICE_AGREEMENT_ID] = @said
			AND cm.[CHARGE_MASTER_USAGE_CODE] = 5 -- Physician Procedure
			AND (cm.[PATIENT_CLASS_ID] = c.[PATIENT_CLASS_ID] OR CM.[PATIENT_CLASS_ID] = -1)
			AND (
				ISNULL(sa.[USE_PAYOR_CLASS_IND], 0) = 0
				OR (NULLIF(sap.[PAYOR_CLASS_ID], -1) IS NULL AND NULLIF(ffc.[PAYOR_CLASS_ID], -1) IS NULL)
				OR cm.[CPT_CODE] NOT IN 
				(
					SELECT
						[CODE_VALUE]
					FROM
						[CODE_LIST_USAGE] u
						JOIN [CODE_LIST] l ON l.[CODE_LIST_ID] = u.[CODE_LIST_ID]
						JOIN [CODE_LIST_ITEM] i ON i.[CODE_LIST_ID] = l.[CODE_LIST_ID]
						JOIN [PAYOR_CLASS] p ON p.[PAYOR_CLASS_ID] = u.[ASSIGNMENT_ID]
						WHERE u.[CODE_LIST_USAGE_CODE] = 'PayorClassCPTExclusion'
						AND p.[PAYOR_CLASS_ID] = ISNULL(NULLIF(sap.[PAYOR_CLASS_ID], -1), ffc.[PAYOR_CLASS_ID])
						AND DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) BETWEEN u.[EFFECTIVE_DTTM] AND u.[EXPIRATION_DTTM]
						AND DATEADD(DAY, DATEDIFF(DAY, 0, GETDATE()), 0) BETWEEN i.[EFFECTIVE_DTTM] AND i.[EXPIRATION_DTTM]
				)
			);

	PRINT('Collect Payor Type')

END;
GO
