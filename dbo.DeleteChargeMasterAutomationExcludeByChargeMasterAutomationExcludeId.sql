SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
	@ChargeMasterAutomationExcludeId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO
