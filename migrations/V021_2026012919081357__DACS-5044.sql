----------------------------------------
-- 01) DACS-5044 - create table UrgentCareHistoryWithProvider.SQL
----------------------------------------
USE [RevCycleDB]
GO

CREATE TABLE [dbo].[UrgentCareHistoryWithProvider](
	[UrgentCareHistoryWithProviderId] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ServiceAgreementId] [int] NOT NULL,
	[MedicalRecordNumber] [varchar](50) NOT NULL,
	[DateOfService] [datetime] NOT NULL,
	[PatientFirstName] [varchar](128) NULL,
	[PatientMiddleName] [varchar](128) NULL,
	[PatientLastName] [varchar](128) NULL,
	[PatientDateOfBirth] [datetime] NOT NULL,
	[ProviderIdentifier] [varchar](15) NULL,
 CONSTRAINT [PK_UrgentCareHistoryWithProvider] PRIMARY KEY CLUSTERED 
(
	[UrgentCareHistoryWithProviderId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[UrgentCareHistoryWithProvider] ADD  CONSTRAINT [DF_UrgentCareHistoryWithProvider_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[UrgentCareHistoryWithProvider] ADD  CONSTRAINT [DF_UrgentCareHistoryWithProvider_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[UrgentCareHistoryWithProvider]  WITH CHECK ADD CONSTRAINT [FK_UrgentCareHistoryWithProvider_SERVICE_AGREEMENT] FOREIGN KEY([ServiceAgreementId])
REFERENCES [dbo].[SERVICE_AGREEMENT] ([SERVICE_AGREEMENT_ID])
GO

ALTER TABLE [dbo].[UrgentCareHistoryWithProvider] CHECK CONSTRAINT [FK_UrgentCareHistoryWithProvider_SERVICE_AGREEMENT]
GO

CREATE NONCLUSTERED INDEX [IX_UrgentCareHistoryWithProvider_SvcAgrmntIdMedRecNbrPrvdrId] ON [dbo].[UrgentCareHistoryWithProvider]
(
	[ServiceAgreementId],  [MedicalRecordNumber]
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO

------------------------------------------------------------------------------------
-- 02) DACS-5044 - create procs for UrgentCareHistoryWithProvider.SQL
------------------------------------------------------------------------------------
USE [RevCycleDB]
GO
---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertUrgentCareHistoryWithProvider', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertUrgentCareHistoryWithProvider.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertUrgentCareHistoryWithProvider
END
GO

IF OBJECT_ID('dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
END
GO
IF OBJECT_ID('dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProvider]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProvider].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProvider]
END
GO

IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]
END
GO
IF OBJECT_ID('[dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertUrgentCareHistoryWithProvider', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertUrgentCareHistoryWithProvider
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ServiceAgreementId int
	,@MedicalRecordNumber varchar(50)
	,@DateOfService datetime
	,@PatientFirstName varchar(128) = NULL
	,@PatientMiddleName varchar(128) = NULL
	,@PatientLastName varchar(128) = NULL
	,@PatientDateOfBirth datetime
	,@ProviderIdentifier varchar(15) = NULL
	,@UrgentCareHistoryWithProviderId int OUTPUT
AS

INSERT INTO [dbo].[UrgentCareHistoryWithProvider]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ServiceAgreementId]
	,[MedicalRecordNumber]
	,[DateOfService]
	,[PatientFirstName]
	,[PatientMiddleName]
	,[PatientLastName]
	,[PatientDateOfBirth]
	,[ProviderIdentifier]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ServiceAgreementId
	,@MedicalRecordNumber
	,@DateOfService
	,@PatientFirstName
	,@PatientMiddleName
	,@PatientLastName
	,@PatientDateOfBirth
	,@ProviderIdentifier 
)

SET @UrgentCareHistoryWithProviderId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
	 @UrgentCareHistoryWithProviderId int
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ServiceAgreementId int
	,@MedicalRecordNumber varchar(50)
	,@DateOfService datetime
	,@PatientFirstName varchar(128) = NULL
	,@PatientMiddleName varchar(128) = NULL
	,@PatientLastName varchar(128) = NULL
	,@PatientDateOfBirth datetime
	,@ProviderIdentifier varchar(15) = NULL
AS

UPDATE [dbo].[UrgentCareHistoryWithProvider] SET
	 [CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
	,[ServiceAgreementId] = @ServiceAgreementId
	,[MedicalRecordNumber] = @MedicalRecordNumber
	,[DateOfService] = @DateOfService
	,[PatientFirstName] = @PatientFirstName
	,[PatientMiddleName] = @PatientMiddleName
	,[PatientLastName] = @PatientLastName
	,[PatientDateOfBirth] = @PatientDateOfBirth
	,[ProviderIdentifier] = @ProviderIdentifier
WHERE
	[UrgentCareHistoryWithProviderId] = @UrgentCareHistoryWithProviderId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId
	@UrgentCareHistoryWithProviderId int
AS

DELETE 
	FROM [dbo].[UrgentCareHistoryWithProvider]
WHERE
	[UrgentCareHistoryWithProviderId] = @UrgentCareHistoryWithProviderId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByUrgentCareHistoryWithProviderId]
	@UrgentCareHistoryWithProviderId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId]
	,[UrgentCareHistoryWithProvider].[DateTimeCreated]
	,[UrgentCareHistoryWithProvider].[CreatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[DateTimeLastUpdated]
	,[UrgentCareHistoryWithProvider].[LastUpdatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[ServiceAgreementId]
	,[UrgentCareHistoryWithProvider].[MedicalRecordNumber]
	,[UrgentCareHistoryWithProvider].[DateOfService]
	,[UrgentCareHistoryWithProvider].[PatientFirstName]
	,[UrgentCareHistoryWithProvider].[PatientMiddleName]
	,[UrgentCareHistoryWithProvider].[PatientLastName]
	,[UrgentCareHistoryWithProvider].[PatientDateOfBirth]
	,[UrgentCareHistoryWithProvider].[ProviderIdentifier]
FROM
	[dbo].[UrgentCareHistoryWithProvider]
WHERE
	[UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] = @UrgentCareHistoryWithProviderId

GO	
		
------------------------------------------------------------------
-- Unscoped Select Sproc
------------------------------------------------------------------
RAISERROR('Creating unscoped select stored procedure:', 0, 1) WITH NOWAIT;	

RAISERROR('...creating [dbo].[SelectUrgentCareHistoryWithProvider]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUrgentCareHistoryWithProvider]
	 @PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[UrgentCareHistoryWithProviderId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (UrgentCareHistoryWithProviderId) ' +
		   'SELECT [UrgentCareHistoryWithProviderId] ' +
		   'FROM [UrgentCareHistoryWithProvider] ' 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' WHERE (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [UrgentCareHistoryWithProvider].[DateTimeCreated]'

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId]
	,[UrgentCareHistoryWithProvider].[DateTimeCreated]
	,[UrgentCareHistoryWithProvider].[CreatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[DateTimeLastUpdated]
	,[UrgentCareHistoryWithProvider].[LastUpdatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[ServiceAgreementId]
	,[UrgentCareHistoryWithProvider].[MedicalRecordNumber]
	,[UrgentCareHistoryWithProvider].[DateOfService]
	,[UrgentCareHistoryWithProvider].[PatientFirstName]
	,[UrgentCareHistoryWithProvider].[PatientMiddleName]
	,[UrgentCareHistoryWithProvider].[PatientLastName]
	,[UrgentCareHistoryWithProvider].[PatientDateOfBirth]
	,[UrgentCareHistoryWithProvider].[ProviderIdentifier]
FROM
	#tmp [tmp]
	INNER JOIN [UrgentCareHistoryWithProvider] 
			ON [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] = [tmp].[UrgentCareHistoryWithProviderId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementIdAndMedicalRecordNumber]
	 @ServiceAgreementId int
	,@MedicalRecordNumber varchar(50)
	,@PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[UrgentCareHistoryWithProviderId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (UrgentCareHistoryWithProviderId) ' +
		   'SELECT [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] ' +
		   'FROM [UrgentCareHistoryWithProvider] ' +
		   'WHERE [UrgentCareHistoryWithProvider].[ServiceAgreementId] = ' + CAST(@ServiceAgreementId AS VARCHAR(10)) + 
           '  AND [UrgentCareHistoryWithProvider].[MedicalRecordNumber] = ' + @MedicalRecordNumber 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [UrgentCareHistoryWithProvider].[DateTimeCreated] '

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex  + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId]
	,[UrgentCareHistoryWithProvider].[DateTimeCreated]
	,[UrgentCareHistoryWithProvider].[CreatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[DateTimeLastUpdated]
	,[UrgentCareHistoryWithProvider].[LastUpdatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[ServiceAgreementId]
	,[UrgentCareHistoryWithProvider].[MedicalRecordNumber]
	,[UrgentCareHistoryWithProvider].[DateOfService]
	,[UrgentCareHistoryWithProvider].[PatientFirstName]
	,[UrgentCareHistoryWithProvider].[PatientMiddleName]
	,[UrgentCareHistoryWithProvider].[PatientLastName]
	,[UrgentCareHistoryWithProvider].[PatientDateOfBirth]
	,[UrgentCareHistoryWithProvider].[ProviderIdentifier]
FROM
	#tmp [tmp]
	INNER JOIN [UrgentCareHistoryWithProvider] 
			ON [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] = [tmp].[UrgentCareHistoryWithProviderId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

RAISERROR('...creating [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectUrgentCareHistoryWithProviderByServiceAgreementId]
	 @ServiceAgreementId int
	,@PageIndex int = NULL
    ,@PageSize int = 25
    ,@WhereClause varchar(1000) = NULL
    ,@OrderByClause varchar(250) = NULL
    ,@RecordCount int OUTPUT
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--[ID LIST]------------------------------------------------------

CREATE TABLE #tmp
(
	[IndexId] int IDENTITY (1, 1) NOT NULL,
	[UrgentCareHistoryWithProviderId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (UrgentCareHistoryWithProviderId) ' +
		   'SELECT [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] ' +
		   'FROM [UrgentCareHistoryWithProvider] ' +
		   'WHERE [UrgentCareHistoryWithProvider].[ServiceAgreementId] = ' + CAST(@ServiceAgreementId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [UrgentCareHistoryWithProvider].[DateTimeCreated] '

EXEC sp_executesql @sql

--[RANGE]----------------------------------------------------------

SELECT @RecordCount = @@ROWCOUNT

DECLARE @FirstRecord int
DECLARE @LastRecord  int

IF @PageIndex IS NOT NULL
BEGIN
	SET @FirstRecord = (@PageIndex * @PageSize) + 1
	SET @LastRecord  = (@PageIndex  + 1) * @PageSize
END
ELSE
BEGIN
	SET @FirstRecord = 1
	SET @LastRecord  = @RecordCount
END

--[DATA]------------------------------------------------------------

SELECT
	 [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId]
	,[UrgentCareHistoryWithProvider].[DateTimeCreated]
	,[UrgentCareHistoryWithProvider].[CreatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[DateTimeLastUpdated]
	,[UrgentCareHistoryWithProvider].[LastUpdatedByUserProfileId]
	,[UrgentCareHistoryWithProvider].[ServiceAgreementId]
	,[UrgentCareHistoryWithProvider].[MedicalRecordNumber]
	,[UrgentCareHistoryWithProvider].[DateOfService]
	,[UrgentCareHistoryWithProvider].[PatientFirstName]
	,[UrgentCareHistoryWithProvider].[PatientMiddleName]
	,[UrgentCareHistoryWithProvider].[PatientLastName]
	,[UrgentCareHistoryWithProvider].[PatientDateOfBirth]
	,[UrgentCareHistoryWithProvider].[ProviderIdentifier]
FROM
	#tmp [tmp]
	INNER JOIN [UrgentCareHistoryWithProvider] 
			ON [UrgentCareHistoryWithProvider].[UrgentCareHistoryWithProviderId] = [tmp].[UrgentCareHistoryWithProviderId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO
