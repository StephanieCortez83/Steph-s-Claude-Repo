SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[TYPE_CODE] WHERE [DESCRIPTION] IN ('Enable/Disables DACS-4958 SPROC variant within FacilityProfessionalDAO.cs'))
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
			'ApplicationFeatureTypeCode'                                       				--NAME
		   ,'CAB_4958'                                                    					--KEY
		   ,7                                                                  				--VALUE
		   ,'CAB_4958'                                                    					--DISPLAY_NAME
		   ,'CAB_4958'                                                         				--SHORT_NAME
		   ,'Enable/Disables DACS-4958 SPROC variant within FacilityProfessionalDAO.cs' 	--DESCRIPTION
		)
ELSE
	PRINT('Type Code already exists.  Action skipped.');
GO

DECLARE @dtCreated DATETIME = GETDATE();
DECLARE @Uid INT = 10149;

IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[ApplicationFeature] WHERE [ApplicationFeatureDomainObjectTypeCode] = 5 AND [DomainObjectId] = 2147483647 AND [ApplicationFeatureTypeCode] = 7)
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
			,7
		)
ELSE
	PRINT('Application Feature already exists.  Action skipped.');
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectFacilityProfessionalById]
	 @FacilityProfessionalId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED; 

	SELECT
		 [FACILITY_PROF_ID]
		,[FACILITY_ID]
		,[SERVICE_AGREEMENT_ID]
		,[ROLE_ID]
		,[TITLE]
		,[FIRST_NAME]
		,[MIDDLE_NAME]
		,[LAST_NAME]
		,[NAME_SUFFIX]
		,[ADDR_LINE_1]
		,[ADDR_LINE_2]
		,[CITY]
		,[STATE]
		,[POSTAL_CODE]
		,[PHONE_AREA_CODE]
		,[PHONE_NUMBER]
		,[PHONE_EXT]
		,[FAX_AREA_CODE]
		,[FAX_NUMBER]
		,[EMAIL_ADDRESS]
		,[EMPLOYEE_IDENTIFIER]
		,[UPIR_ID]
		,[CREATION_DATE_TIME]
		,[CREATING_USER_PROFILE_ID]
		,[CHANGED_DATE_TIME]
		,[CHANGING_USER_PROFILE_ID]
		,[PROVIDER_BUSINESS_UNIT_ID]
		,[SPECIALTY]
		,[SECONDARY_EMPLOYEE_ID]
		,[LOCUM_TENENS]
		,[EFFECTIVE_DATE]
		,[EXPIRATION_DATE]
		,[SUPERVISING_EMPLOYEE_ID]
		,[UNSPECIFIED_PROVIDER_IND]
		,[CREDENTIALS]
	FROM
		[FACILITY_PROFESSIONAL]
	WHERE
		[FACILITY_PROF_ID] = @FacilityProfessionalId;
END
GO
