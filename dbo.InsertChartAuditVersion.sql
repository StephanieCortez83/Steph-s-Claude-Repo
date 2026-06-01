SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[InsertChartAuditVersion]
	 @ChartAuditId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@VersionNumber int
	,@PreviousChartAuditVersionId int = NULL
	,@ChartAuditVersionId int OUTPUT
AS

INSERT INTO [dbo].[ChartAuditVersion]
(
	 [ChartAuditId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[VersionNumber]
	,[PreviousChartAuditVersionId]
)
VALUES
(
	 @ChartAuditId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@VersionNumber
	,@PreviousChartAuditVersionId 
)

SET @ChartAuditVersionId = @@IDENTITY


GO
