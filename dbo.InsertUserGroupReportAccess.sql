SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertUserGroupReportAccess]
	 @EffectiveDate datetime
	,@LastUpdatedByUserProfileId int = NULL
	,@UserGroupId int
	,@CreatedByUserProfileId int = NULL
	,@ExpirationDate datetime = NULL
	,@ReportName varchar(256) = NULL
	,@UserGroupReportAccessId int OUTPUT
AS

INSERT INTO [dbo].[UserGroupReportAccess]
(
	 [EffectiveDate]
	,[LastUpdatedByUserProfileId]
	,[UserGroupId]
	,[CreatedByUserProfileId]
	,[ExpirationDate]
	,[ReportName]
)
VALUES
(
	 @EffectiveDate
	,@LastUpdatedByUserProfileId
	,@UserGroupId
	,@CreatedByUserProfileId
	,@ExpirationDate
	,@ReportName 
)

SET @UserGroupReportAccessId = @@IDENTITY

GO
