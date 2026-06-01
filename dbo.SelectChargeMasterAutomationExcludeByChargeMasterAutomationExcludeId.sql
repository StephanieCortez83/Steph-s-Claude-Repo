SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
	@ChargeMasterAutomationExcludeId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	[dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO
