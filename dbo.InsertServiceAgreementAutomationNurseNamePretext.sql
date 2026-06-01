SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertServiceAgreementAutomationNurseNamePretext]
	 @ServiceAgreementId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@NurseNamePretext varchar(100)
	,@ServiceAgreementAutomationNurseNamePretextId int OUTPUT
AS

INSERT INTO [dbo].[ServiceAgreementAutomationNurseNamePretext]
(
	 [ServiceAgreementId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[NurseNamePretext]
)
VALUES
(
	 @ServiceAgreementId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@NurseNamePretext 
)

SET @ServiceAgreementAutomationNurseNamePretextId = @@IDENTITY

GO
