SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4893 SPROC variant within FacilityProcedureEvaluationListDAO.cs'))
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
		   ,'CAB_4893'                                                    							--KEY
		   ,17                                                                						--VALUE
		   ,'CAB_4893'                                                    							--DISPLAY_NAME
		   ,'CAB_4893'                                                        						--SHORT_NAME
		   ,'Enable/Disables DACS-4893 SPROC variant within FacilityProcedureEvaluationListDAO.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 17)
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
			,17
		)
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityProcedureEvaluationListItem]
	 @ChartId INT
	,@CategoryId INT = NULL
	,@ExcludeInjectionsAndInfusions BIT = 1
	,@FilterInvalidProcedures BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	--------------------------------
	-- get some chart columns
	--------------------------------
	DECLARE
		 @ServiceAgreementID INT = -1
		,@PatientDispositionID INT = -1
		,@ObservationPatientSourceID INT = -1
		,@InitialChargeMasterDeptID INT = -1
		,@PatientClassID INT = -1
		,@TimeOfService DATETIME
	;

	SELECT
		 @ServiceAgreementID = [SERVICE_AGREEMENT_ID]
		,@PatientDispositionID = [PATIENT_DISPOSITION_ID]
		,@ObservationPatientSourceID = [OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID]
		,@InitialChargeMasterDeptID = [INITIAL_CHARGE_MASTER_DEPT_ID]
		,@PatientClassID = [PATIENT_CLASS_ID]
		,@TimeOfService = [TIME_OF_SERVICE]
	FROM
		[CHART]
	WHERE
		[CHART_ID] = @ChartId;

	IF @ServiceAgreementID IS NULL OR @ServiceAgreementID <= 0
	BEGIN
		PRINT ('Bad SaId')
		RETURN;
	END;

	--------------------------------
	-- Operation Flags
	--------------------------------
	DECLARE
		 @limitToObservationDepartments BIT = 0
		,@excludeObservationDepartments BIT = IIF(@PatientDispositionID = 5, 0, 1);  -- not OBSERVATION
	;
	
	IF @PatientDispositionID = 5 AND @ObservationPatientSourceID > 0
	BEGIN
		IF (SELECT [OBSERVATION_IND] FROM [CHARGE_MASTER_DEPARTMENT] WHERE [CHARGE_MASTER_DEPT_ID] = @InitialChargeMasterDeptID) = 1
		BEGIN
			IF (SELECT [OBSERVATION_PATIENT_ARRIVAL_SOURCE_CD] FROM [SERVICE_AGREEMENT_OBSERVATION_PATIENT_ARRIVAL_SOURCE] WHERE [OBSERVATION_PATIENT_ARRIVAL_SOURCE_ID] = @ObservationPatientSourceID) <> 1
				SET @limitToObservationDepartments = 1
		END;
	END;
	
	--------------------------------
	-- replaces: new FacilityProcedureEvaluationListDAO(requestManager).LoadData(chart, 0, "ASC", false, categoryId)
	--------------------------------
	DROP TABLE IF EXISTS #TmpFacProcsELTable;

	SELECT
		ROW_NUMBER() OVER (ORDER BY CMC.[DESCRIPTION], CM.[DISPLAY_SEQ], CM.[CPT_CODE]) AS RowNum -- or maybe: ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum,
		,cm.[CHARGE_MASTER_ID]
		,cm.[CHARGE_MASTER_CATEGORY_ID]
		-- save for later -- ,cm.[DESCRIPTION]
		-- save for later -- ,cm.[LONG_DESCRIPTION]
		-- save for later -- ,cm.[CPT_CODE]
		-- save for later -- ,cm.[BILLING_CODE]
		-- save for later -- ,cm.[MODIFIER_REQUIRED]
		,fpe.[ICD9_CODE]
		,fpe.[ICD_10_CODE]
		,cmc.[DESCRIPTION]
		,fpe.[QUANTITY]
		,fpe.[MODIFIERS]
		,fpe.[ANESTHESIA_TYPE_ID]
		,fpe.[PROCEDURE_DATE]
		,fpe.[TRANSACTION_ID]
		,fpe.[PHYSICIAN_ID]
		,fpe.[INSUFFICIENT_DOCUMENTATION_TO_BILL]
		,fpe.[ADD_TO_PHYSICIAN_PROCEDURE]
		,cm.[MAX_QUANTITY]
		-- save for later -- ,cm.[ALLOW_NEGATIVE_UNITS_IND]
		,fpe.[ICD_10_PCS_CODE]
		,cm.[CHARGE_MASTER_DEPT_ID]
		,CASE
			(
				SELECT TOP 1 1 
				FROM
					[CODER_QA_REPORT_EXCLUSION] ex 
				WHERE
					ex.[SOURCE_RECORD_TABLE_NAME] = 'FACILITY_PROCEDURE_EVALUATION'
					AND [KEY_VALUE_1] = fpe.CHART_ID
					AND [KEY_VALUE_2] = CAST(fpe.[FACILITY_PROCEDURE_ID] as VARCHAR(15)) 
			)
			WHEN 1 THEN 1
			ELSE 0
			END
			AS [EXCLUDE_FROM_CODER_QA_REPORT]
		,CAST( IIF((SELECT
						TOP 1 1
					FROM
						[ICD_10_PCS_CPT_XREF]
					WHERE
						[CPT_CODE] COLLATE Latin1_General_CI_AI = cm.[CPT_CODE]
			) = 1, 1 , 0) AS BIT) [COLLECT_ICD10_PCS_IND]
		,CAST( IIF((SELECT TOP 1 1
					FROM
						[CHARGE_MASTER_MODIFIER]
					WHERE
						[CHARGE_MASTER_ID] = cm.[CHARGE_MASTER_ID]
			) = 1, 1 , 0) AS BIT) [MODIFIERS_AVAILABLE]
		,cmd.[OBSERVATION_IND]
		,cmc.[INFUSION_CATEGORY]
	INTO #TmpFacProcsELTable
	FROM 
		[CHARGE_MASTER] cm 
		LEFT OUTER JOIN [FACILITY_PROCEDURE_EVALUATION] fpe	ON cm.[CHARGE_MASTER_ID] = fpe.[FACILITY_PROCEDURE_ID] AND ([CHART_ID] = @ChartID OR [CHART_ID] IS NULL)
	    JOIN [CHARGE_MASTER_CATEGORY] cmc ON cm.[CHARGE_MASTER_CATEGORY_ID] = cmc.[CHARGE_MASTER_CATEGORY_ID]
		JOIN [CHARGE_MASTER_DEPARTMENT] cmd ON cm.[CHARGE_MASTER_DEPT_ID] = cmd.[CHARGE_MASTER_DEPT_ID]
	WHERE
		cm.[SERVICE_AGREEMENT_ID] = @ServiceAgreementID
		AND cm.[CHARGE_MASTER_USAGE_CODE] = 3
		AND (cm.[PATIENT_CLASS_ID] = @PatientClassID OR cm.[PATIENT_CLASS_ID] = -1)
		AND @TimeOfService BETWEEN cm.[EFFECTIVE_DATE] AND cm.[EXPIRATION_DATE]
	ORDER BY
		CMC.[DESCRIPTION], CM.[DISPLAY_SEQ], CM.[CPT_CODE];

	IF (SELECT TOP 1 1 FROM #TmpFacProcsELTable) IS NULL
	BEGIN
		PRINT ('No root data')
		RETURN;
	END;

	DECLARE @countTmpFacProcsELTable INT = (SELECT COUNT(*) FROM #TmpFacProcsELTable);
	PRINT ('#TmpFacProcsELTable (1) = ' + CAST (@countTmpFacProcsELTable AS VARCHAR(30)));

	--------------------------------
	-- now remove all optional data records not needed
	--------------------------------
	IF @limitToObservationDepartments = 1
		DELETE FROM #TmpFacProcsELTable WHERE [OBSERVATION_IND] <> 1;

	IF @excludeObservationDepartments = 1
		DELETE FROM #TmpFacProcsELTable WHERE [OBSERVATION_IND] = 1;

	IF @CategoryId IS NOT NULL
		DELETE FROM #TmpFacProcsELTable WHERE [CHARGE_MASTER_CATEGORY_ID] <> @CategoryId;

	IF @excludeInjectionsAndInfusions = 1
		DELETE FROM #TmpFacProcsELTable WHERE [INFUSION_CATEGORY] = 1;

	IF @FilterInvalidProcedures = 1
		DELETE FROM #TmpFacProcsELTable WHERE [CHARGE_MASTER_DEPT_ID] < 0 OR [CHARGE_MASTER_DEPT_ID] IS NULL

	IF (SELECT TOP 1 1 FROM #TmpFacProcsELTable) IS NULL
	BEGIN
		PRINT ('No data after filtering')
		RETURN;
	END;
		
	--------------------------------
	-- return some results
	--------------------------------
	SELECT
		 tfp.[CHARGE_MASTER_ID]
		,tfp.[CHARGE_MASTER_CATEGORY_ID]
		,cm.[DESCRIPTION]
		,cm.[LONG_DESCRIPTION]
		,cm.[CPT_CODE]
		,cm.[BILLING_CODE]
		,cm.[MODIFIER_REQUIRED]
		,tfp.[ICD9_CODE]
		,tfp.[ICD_10_CODE]
		,tfp.[DESCRIPTION]
		,tfp.[QUANTITY]
		,tfp.[MODIFIERS]
		,tfp.[ANESTHESIA_TYPE_ID]
		,tfp.[PROCEDURE_DATE]
		,tfp.[TRANSACTION_ID]
		,tfp.[PHYSICIAN_ID]
		,tfp.[INSUFFICIENT_DOCUMENTATION_TO_BILL]
		,tfp.[ADD_TO_PHYSICIAN_PROCEDURE]
		,tfp.[MAX_QUANTITY]
		,cm.[ALLOW_NEGATIVE_UNITS_IND]
		,tfp.[ICD_10_PCS_CODE]
		,tfp.[CHARGE_MASTER_DEPT_ID]
		,tfp.[EXCLUDE_FROM_CODER_QA_REPORT]
		,tfp.[COLLECT_ICD10_PCS_IND]
		,tfp.[MODIFIERS_AVAILABLE]
	FROM 
		#TmpFacProcsELTable tfp
		INNER JOIN [CHARGE_MASTER] cm
				ON cm.[CHARGE_MASTER_ID] = tfp.[CHARGE_MASTER_ID]
	ORDER BY
		RowNum;
		
END;
GO

