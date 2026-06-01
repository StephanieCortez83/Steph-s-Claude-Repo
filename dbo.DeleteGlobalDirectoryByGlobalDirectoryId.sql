SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteGlobalDirectoryByGlobalDirectoryId]
	@GlobalDirectoryId int
AS

DELETE 
	FROM [dbo].[GlobalDirectory]
WHERE
	[GlobalDirectoryId] = @GlobalDirectoryId

GO
