SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteServiceAgreementAutomationNurseNamePretextByServiceAgreementAutomationNurseNamePretextId]
	@ServiceAgreementAutomationNurseNamePretextId int
AS

DELETE 
	FROM [dbo].[ServiceAgreementAutomationNurseNamePretext]
WHERE
	[ServiceAgreementAutomationNurseNamePretextId] = @ServiceAgreementAutomationNurseNamePretextId

GO
