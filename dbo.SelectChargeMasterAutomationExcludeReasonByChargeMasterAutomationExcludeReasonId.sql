SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
	@ChargeMasterAutomationExcludeReasonId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChargeMasterAutomationExcludeReason].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExcludeReason].[Description]
	,[ChargeMasterAutomationExcludeReason].[DateTimeExpiration]
	,[ChargeMasterAutomationExcludeReason].[DateTimeEffective]
	,[ChargeMasterAutomationExcludeReason].[DateTimeCreated]
	,[ChargeMasterAutomationExcludeReason].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExcludeReason].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExcludeReason].[LastUpdatedByUserProfileId]
FROM
	[dbo].[ChargeMasterAutomationExcludeReason]
WHERE
	[ChargeMasterAutomationExcludeReason].[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId

GO
