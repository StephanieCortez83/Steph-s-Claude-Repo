SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteServiceAgreementAutomationWarningFlagsByServiceAgreementAutomationWarningFlagsId]
	@ServiceAgreementAutomationWarningFlagsId int
AS

DELETE 
	FROM [dbo].[ServiceAgreementAutomationWarningFlags]
WHERE
	[ServiceAgreementAutomationWarningFlagsId] = @ServiceAgreementAutomationWarningFlagsId

GO
