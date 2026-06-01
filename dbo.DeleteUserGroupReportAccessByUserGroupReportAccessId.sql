SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteUserGroupReportAccessByUserGroupReportAccessId]
	@UserGroupReportAccessId int
AS

DELETE 
	FROM [dbo].[UserGroupReportAccess]
WHERE
	[UserGroupReportAccessId] = @UserGroupReportAccessId

GO
