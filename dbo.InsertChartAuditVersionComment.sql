SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
/* Only use this section if you need to drop previously created stored procs. 
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChartAuditVersionComment', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChartAuditVersionComment.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChartAuditVersionComment
END
GO

IF OBJECT_ID('dbo.UpdateByChartAuditVersionCommentByChartAuditVersionCommentId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChartAuditVersionCommentByChartAuditVersionCommentId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChartAuditVersionCommentByChartAuditVersionCommentId
END
GO
IF OBJECT_ID('dbo.DeleteChartAuditVersionCommentByChartAuditVersionCommentId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChartAuditVersionCommentByChartAuditVersionCommentId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChartAuditVersionCommentByChartAuditVersionCommentId
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditVersionCommentByChartAuditVersionCommentId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditVersionCommentByChartAuditVersionCommentId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditVersionCommentByChartAuditVersionCommentId]
END
GO

IF OBJECT_ID('[dbo].[SelectChartAuditVersionCommentByChartAuditVersionIdAndChartAuditSectionTypeCode]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditVersionCommentByChartAuditVersionIdAndChartAuditSectionTypeCode].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditVersionCommentByChartAuditVersionIdAndChartAuditSectionTypeCode]
END
GO
IF OBJECT_ID('[dbo].[SelectChartAuditVersionCommentByChartAuditVersionId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChartAuditVersionCommentByChartAuditVersionId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChartAuditVersionCommentByChartAuditVersionId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChartAuditVersionComment', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
*/

CREATE   PROCEDURE [dbo].[InsertChartAuditVersionComment]
	 @CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartAuditVersionId int
	,@ChartAuditSectionTypeCode int
	,@Comment varchar(500) = NULL
	,@ChartAuditVersionCommentId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditVersionComment]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartAuditVersionId]
	,[ChartAuditSectionTypeCode]
	,[Comment]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartAuditVersionId
	,@ChartAuditSectionTypeCode
	,@Comment 
)

SET @ChartAuditVersionCommentId = @@IDENTITY

GO
