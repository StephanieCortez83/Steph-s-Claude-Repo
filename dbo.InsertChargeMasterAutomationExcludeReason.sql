SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChargeMasterAutomationExcludeReason]
	 @Description varchar(250)
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChargeMasterAutomationExcludeReasonId int OUTPUT
AS

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
(
	 [Description]
	,[DateTimeExpiration]
	,[DateTimeEffective]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @Description
	,@DateTimeExpiration
	,@DateTimeEffective
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ChargeMasterAutomationExcludeReasonId = @@IDENTITY

GO
