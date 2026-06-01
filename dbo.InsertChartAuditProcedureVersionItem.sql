SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/* Need to un comment this section out and drop the procedures if they already exist. 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditProcedureVersionItem', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditProcedureVersionItem.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditProcedureVersionItem
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditProcedureVersionItemByChartAuditProcedureVersionItemId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionIdAndProcedureType]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionIdAndProcedureType].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionIdAndProcedureType]
END
GO
IF OBJECT_ID('[dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditProcedureVersionItemByChartAuditVersionId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditProcedureVersionItem', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

*/

CREATE   PROCEDURE [dbo].[InsertChartAuditProcedureVersionItem]
	 @ChartAuditVersionId int
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditActionTypeCode int
	,@ActionDescription varchar(250) = NULL
	,@PrevChartAuditProcedureVersionItemId int = NULL
	,@IsPreviousVersionCorrect bit
	,@ExcludeFromQA bit
	,@ExcludeFromQAReasonID int = NULL
	,@ProcedureType varchar(2)
	,@CptCode varchar(10) = NULL
	,@ChargeMasterId int = NULL
	,@ChargeMasterDeptId int = NULL
	,@ProcedureDate datetime = NULL
	,@ProviderId int = NULL
	,@Modifier varchar(100) = NULL
	,@Quantity int = NULL
	,@ChartAuditProcedureVersionItemId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditProcedureVersionItem]
(
	 [ChartAuditVersionId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditActionTypeCode]
	,[ActionDescription]
	,[PrevChartAuditProcedureVersionItemId]
	,[IsPreviousVersionCorrect]
	,[ExcludeFromQA]
	,[ExcludeFromQAReasonID]
	,[ProcedureType]
	,[CptCode]
	,[ChargeMasterId]
	,[ChargeMasterDeptId]
	,[ProcedureDate]
	,[ProviderId]
	,[Modifier]
	,[Quantity]
)
VALUES
(
	 @ChartAuditVersionId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditActionTypeCode
	,@ActionDescription
	,@PrevChartAuditProcedureVersionItemId
	,@IsPreviousVersionCorrect
	,@ExcludeFromQA
	,@ExcludeFromQAReasonID
	,@ProcedureType
	,@CptCode
	,@ChargeMasterId
	,@ChargeMasterDeptId
	,@ProcedureDate
	,@ProviderId
	,@Modifier
	,@Quantity 
)

SET @ChartAuditProcedureVersionItemId = @@IDENTITY

GO
