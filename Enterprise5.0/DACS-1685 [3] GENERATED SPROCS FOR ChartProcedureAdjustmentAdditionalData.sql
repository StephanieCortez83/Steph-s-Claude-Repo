 USE [RevCycleDB]
 GO

------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartProcedureAdjustmentAdditionalData', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertChartProcedureAdjustmentAdditionalData
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartId int
	,@PatientClassId int
	,@ChartProcedureAdjustmentAdditionalDataId int OUTPUT
AS

INSERT INTO [dbo].[ChartProcedureAdjustmentAdditionalData]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartId]
	,[PatientClassId]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartId
	,@PatientClassId 
)

SET @ChartProcedureAdjustmentAdditionalDataId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId
	 @ChartProcedureAdjustmentAdditionalDataId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartId int
	,@PatientClassId int
AS

UPDATE [dbo].[ChartProcedureAdjustmentAdditionalData] SET
	 [CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ChartId] = @ChartId
	,[PatientClassId] = @PatientClassId
WHERE
	[ChartProcedureAdjustmentAdditionalDataId] = @ChartProcedureAdjustmentAdditionalDataId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId
	@ChartProcedureAdjustmentAdditionalDataId int
AS

DELETE 
	FROM [dbo].[ChartProcedureAdjustmentAdditionalData]
WHERE
	[ChartProcedureAdjustmentAdditionalDataId] = @ChartProcedureAdjustmentAdditionalDataId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChartProcedureAdjustmentAdditionalDataByChartId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartProcedureAdjustmentAdditionalDataByChartId]
	@ChartId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartProcedureAdjustmentAdditionalData].[ChartProcedureAdjustmentAdditionalDataId]
	,[ChartProcedureAdjustmentAdditionalData].[DateTimeCreated]
	,[ChartProcedureAdjustmentAdditionalData].[CreatedByUserProfileId]
	,[ChartProcedureAdjustmentAdditionalData].[DateTimeLastUpdated]
	,[ChartProcedureAdjustmentAdditionalData].[LastUpdatedByUserProfileId]
	,[ChartProcedureAdjustmentAdditionalData].[ChartId]
	,[ChartProcedureAdjustmentAdditionalData].[PatientClassId]
FROM
	[dbo].[ChartProcedureAdjustmentAdditionalData]
WHERE
	[ChartProcedureAdjustmentAdditionalData].[ChartId] = @ChartId

GO	
		
RAISERROR('...creating [dbo].[SelectChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId]
	@ChartProcedureAdjustmentAdditionalDataId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChartProcedureAdjustmentAdditionalData].[ChartProcedureAdjustmentAdditionalDataId]
	,[ChartProcedureAdjustmentAdditionalData].[DateTimeCreated]
	,[ChartProcedureAdjustmentAdditionalData].[CreatedByUserProfileId]
	,[ChartProcedureAdjustmentAdditionalData].[DateTimeLastUpdated]
	,[ChartProcedureAdjustmentAdditionalData].[LastUpdatedByUserProfileId]
	,[ChartProcedureAdjustmentAdditionalData].[ChartId]
	,[ChartProcedureAdjustmentAdditionalData].[PatientClassId]
FROM
	[dbo].[ChartProcedureAdjustmentAdditionalData]
WHERE
	[ChartProcedureAdjustmentAdditionalData].[ChartProcedureAdjustmentAdditionalDataId] = @ChartProcedureAdjustmentAdditionalDataId

GO	
		
