SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectPhysicianServiceDeterminedRatingsValuesByMultiFactor]
	 @PhysicianServiceClassCD VARCHAR(10)
	,@TimeOfService DATETIME
	,@PhysicianServiceGuidelineId INT
	,@CategoryId INT = 3
	,@PointsSubCat1 INT
	,@PointsSubCat2 INT
	,@PointsSubCat3 INT
	,@Cat1 INT
	,@Cat2 INT
	,@ServiceLevelType INT	
	,@OutSubCatRate1 INT OUTPUT
	,@OutSubCatRate2 INT OUTPUT
	,@OutSubCatRate3 INT OUTPUT
	,@OutCatRate3 INT OUTPUT
	,@OutServiceLevelCd INT OUTPUT
AS  
BEGIN  
	SET NOCOUNT ON;  
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;   

	DECLARE @OutSubCatRate1 INT = -1;
	DECLARE @OutSubCatRate2 INT = -1;
	DECLARE @OutSubCatRate3 INT = -1;
	DECLARE @OutCatRate3 INT = -1;
	DECLARE @OutServiceLevelCd INT = -1;

	SELECT TOP 1
		@OutSubCatRate1 = [RATE]  
	FROM  
		[PHYSICIAN_SERVICE_SUBCAT_RATE]  
	WHERE  
		[PHYSICIAN_SERVICE_CATEGORY_ID] = @CategoryId  
		AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = @PhysicianServiceGuidelineId  
		AND [PHYSICIAN_SERVICE_SUBCATEGORY_ID] = 1  
		AND [PHYSICIAN_SERVICE_CLASS_CD] = @PhysicianServiceClassCD  
		AND @PointsSubCat1 BETWEEN [LOW] AND [HIGH]  
		AND @TimeOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]
		
	SELECT TOP 1
		@OutSubCatRate2 = [RATE]  
	FROM  
		[PHYSICIAN_SERVICE_SUBCAT_RATE]  
	WHERE  
		[PHYSICIAN_SERVICE_CATEGORY_ID] = @CategoryId  
		AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = @PhysicianServiceGuidelineId  
		AND [PHYSICIAN_SERVICE_SUBCATEGORY_ID] = 2  
		AND [PHYSICIAN_SERVICE_CLASS_CD] = @PhysicianServiceClassCD  
		AND @PointsSubCat2 BETWEEN [LOW] AND [HIGH]  
		AND @TimeOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]	

	SELECT TOP 1
		@OutSubCatRate3 = [RATE]  
	FROM  
		[PHYSICIAN_SERVICE_SUBCAT_RATE]  
	WHERE  
		[PHYSICIAN_SERVICE_CATEGORY_ID] = @CategoryId  
		AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = @PhysicianServiceGuidelineId  
		AND [PHYSICIAN_SERVICE_SUBCATEGORY_ID] = 3  
		AND [PHYSICIAN_SERVICE_CLASS_CD] = @PhysicianServiceClassCD  
		AND @PointsSubCat3 BETWEEN [LOW] AND [HIGH]  
		AND @TimeOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]	

	SELECT TOP 1
		@OutCatRate3 = [RATE]
	FROM   
		[PHYSICIAN_SERVICE_CAT_RATE]
	WHERE  
		[PHYSICIAN_SERVICE_CLASS_CD] = @PhysicianServiceClassCD  
		AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = @PhysicianServiceGuidelineId  
		AND [CATEGORY_ID] = @CategoryId  
		AND [SUB_CAT_RATE_1] = @OutSubCatRate1  
		AND [SUB_CAT_RATE_2] = @OutSubCatRate2  
		AND [SUB_CAT_RATE_3] = @OutSubCatRate3
		AND @TimeOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE]			

	SELECT TOP 1
		@OutServiceLevelCd = [SERVICE_LEVEL_CD]  
	FROM   
		[PHYSICIAN_SERVICE_LEVEL]  
	WHERE   
		@TimeOfService BETWEEN [EFFECTIVE_DATE] AND [EXPIRATION_DATE] 
		AND [PHYSICIAN_SERVICE_CLASS_CD] = @PhysicianServiceClassCD  
		AND [PHYSICIAN_SERVICE_GUIDELINE_ID] = @PhysicianServiceGuidelineId  
		AND [PHYSICIAN_SERVICE_TYPE_CD] = @ServiceLevelType  
		AND [CAT_1_RATING] = @Cat1  
		AND [CAT_2_RATING] = @Cat2  
		AND [CAT_3_RATING] = @OutCatRate3

	SELECT @OutSubCatRate1 AS SubCatRate1, @OutSubCatRate2 AS SubCatRate2, @OutSubCatRate3 AS SubCatRate3, @OutCatRate3 AS CatRate3, @OutServiceLevelCd AS ServiceLevelCd;
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4857 SPROC variant within PhysicianServiceEvaluationListDAO.cs'))
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
		   ,'CAB_4857'                                                    							--KEY
		   ,12                                                                 						--VALUE
		   ,'CAB_4857'                                                    							--DISPLAY_NAME
		   ,'CAB_4857'                                                        						--SHORT_NAME
		   ,'Enable/Disables DACS-4857 SPROC variant within PhysicianServiceEvaluationListDAO.cs' 	--DESCRIPTION
		);
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 12)
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
			,12
		);
GO
