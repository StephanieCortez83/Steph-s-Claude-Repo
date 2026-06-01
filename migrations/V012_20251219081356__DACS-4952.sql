SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectIdAndDescriptionFromPatientDisposition]
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT
		 [PATIENT_DISPOSITION_ID]
		,[DESCRIPTION]
	FROM
		[PATIENT_DISPOSITION]
	ORDER BY
		[DESCRIPTION];
END
GO

CREATE   PROCEDURE [dbo].[SelectFromPatientDispositionById]
	@PatientDispositionId INT
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TOP 1
		 [PATIENT_DISPOSITION_ID]
		,[DESCRIPTION]
		,[OUTPATIENT_IND]
	FROM
		[PATIENT_DISPOSITION]
	WHERE
		[PATIENT_DISPOSITION_ID] = @PatientDispositionId;
END
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4952 SPROC variant within SimplePatientDispositionListDAO.cs'))
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
		   ,'CAB_4952'                                                    							--KEY
		   ,10                                                                 						--VALUE
		   ,'CAB_4952'                                                    							--DISPLAY_NAME
		   ,'CAB_4952'                                                        						--SHORT_NAME
		   ,'Enable/Disables DACS-4952 SPROC variant within SimplePatientDispositionListDAO.cs' 	--DESCRIPTION
		)
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 10)
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
			,10
		)
GO
