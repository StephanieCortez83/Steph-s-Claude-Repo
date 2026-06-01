SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChargeMasterAutomationExclude]
	 @ChargeMasterId int
	,@ChargeMasterAutomationExcludeReasonId int
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChargeMasterAutomationExcludeId int OUTPUT
AS

INSERT INTO [dbo].[ChargeMasterAutomationExclude]
(
	 [ChargeMasterId]
	,[ChargeMasterAutomationExcludeReasonId]
	,[DateTimeExpiration]
	,[DateTimeEffective]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @ChargeMasterId
	,@ChargeMasterAutomationExcludeReasonId
	,@DateTimeExpiration
	,@DateTimeEffective
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ChargeMasterAutomationExcludeId = @@IDENTITY

GO
