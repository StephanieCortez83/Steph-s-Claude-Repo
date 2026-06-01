SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4956 SPROC variant within AnesthesiaListDAO.cs'))
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
			'ApplicationFeatureTypeCode'                                       		--NAME
		   ,'CAB_4956'                                                    			--KEY
		   ,8                                                                  		--VALUE
		   ,'CAB_4956'                                                    			--DISPLAY_NAME
		   ,'CAB_4956'                                                 				--SHORT_NAME
		   ,'Enable/Disables DACS-4958 SPROC variant within AnesthesiaListDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 8)
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
			,8
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectAnesthesiaTypeByServiceAgreementId]
	 @ServiceAgreementId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	SELECT
		 [ANESTHESIA_TYPE_ID]
		,[SERVICE_AGREEMENT_ID]
		,[FACILITY_ANESTHESIA_TYPE]
		,[DESCRIPTION]
	FROM
		[ANESTHESIA_TYPE]
	WHERE
		[SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
END
GO
