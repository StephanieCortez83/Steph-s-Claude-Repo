SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[ELMAH_Error_SELECT_BY_ErrorId]
	@ErrorId uniqueidentifier
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ELMAH_Error].[ErrorId]
	,[ELMAH_Error].[Application]
	,[ELMAH_Error].[Host]
	,[ELMAH_Error].[Type]
	,[ELMAH_Error].[Source]
	,[ELMAH_Error].[Message]
	,[ELMAH_Error].[User]
	,[ELMAH_Error].[StatusCode]
	,[ELMAH_Error].[TimeUtc]
	,[ELMAH_Error].[Sequence]
	,[ELMAH_Error].[AllXml]
FROM
	[dbo].[ELMAH_Error]
WHERE
	[ELMAH_Error].[ErrorId] = @ErrorId

GO
