SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
	@ChargeMasterAutomationExcludeReasonId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExcludeReason]
WHERE
	[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId

GO
