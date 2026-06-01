USE [RevCycleDB]
GO

---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChargeMasterAutomationExcludeReason', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChargeMasterAutomationExcludeReason.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChargeMasterAutomationExcludeReason
END
GO

IF OBJECT_ID('dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
END
GO
IF OBJECT_ID('dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
END
GO

------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChargeMasterAutomationExcludeReason', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChargeMasterAutomationExcludeReason
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

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
	 @ChargeMasterAutomationExcludeReasonId int
	,@Description varchar(250)
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
AS

UPDATE [dbo].[ChargeMasterAutomationExcludeReason] SET
	 [Description] = @Description
	,[DateTimeExpiration] = @DateTimeExpiration
	,[DateTimeEffective] = @DateTimeEffective
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
WHERE
	[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
	@ChargeMasterAutomationExcludeReasonId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExcludeReason]
WHERE
	[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
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
		