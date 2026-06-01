SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertServiceAgreementAutomationWarningFlags]
	 @ServiceAgreementId int
	,@CptCode varchar(5) = NULL
	,@AuditFlagVerbiage varchar(100) = NULL
	,@Status bit = NULL
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ServiceAgreementAutomationWarningFlagsId int OUTPUT
AS

INSERT INTO [dbo].[ServiceAgreementAutomationWarningFlags]
(
	 [ServiceAgreementId]
	,[CptCode]
	,[AuditFlagVerbiage]
	,[Status]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @ServiceAgreementId
	,@CptCode
	,@AuditFlagVerbiage
	,@Status
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ServiceAgreementAutomationWarningFlagsId = @@IDENTITY

GO
