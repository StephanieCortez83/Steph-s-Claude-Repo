SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertGlobalDirectory]
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@DateTimeLastEnabled datetime = NULL
	,@LastEnabledByUserProfileId int = NULL
	,@DateTimeLastDisabled datetime = NULL
	,@LastDisabledByUserProfileId int = NULL
	,@Name varchar(250)
	,@ActivationTypeCd int
	,@ActivationTypeName varchar(250)
	,@GlobalDirectoryId int OUTPUT
AS

INSERT INTO [dbo].[GlobalDirectory]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[DateTimeLastEnabled]
	,[LastEnabledByUserProfileId]
	,[DateTimeLastDisabled]
	,[LastDisabledByUserProfileId]
	,[Name]
	,[ActivationTypeCd]
	,[ActivationTypeName]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@DateTimeLastEnabled
	,@LastEnabledByUserProfileId
	,@DateTimeLastDisabled
	,@LastDisabledByUserProfileId
	,@Name
	,@ActivationTypeCd
	,@ActivationTypeName 
)

SET @GlobalDirectoryId = @@IDENTITY

GO
