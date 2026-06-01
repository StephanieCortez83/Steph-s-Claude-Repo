USE RevCycleDB;
SET XACT_ABORT ON;
BEGIN TRANSACTION

-- Start of 01) DACS-2369 - alter table - SERVICE_AGREEMENT_RATE.sql

--------------------------------------------------
-- 01) DACS-2369 - alter table - SERVICE_AGREEMENT_RATE.sql
--------------------------------------------------

GO

SELECT TOP (1) 1 FROM [dbo].[SERVICE_AGREEMENT_RATE] WITH (TABLOCKX)

ALTER TABLE [dbo].[SERVICE_AGREEMENT_RATE]
	  ADD [PATIENT_CLASS_ID] INT NULL
	;

GO
-- End of 01) DACS-2369 - alter table - SERVICE_AGREEMENT_RATE.sql
GO

-- Start of 01) DACS-2252 - alter table CHARGE_MASTER - add age min max fields.SQL

---------------------------------------------------------------------------------------------------
-- 01) DACS-2252 - alter table CHARGE_MASTER - add age min max fields.SQL
-- *Note:  This script alters the highly used Charge_master table
---------------------------------------------------------------------------------------------------
GO

SELECT TOP (1) 1 FROM [dbo].[CHARGE_MASTER] WITH (TABLOCKX)

ALTER TABLE [dbo].[CHARGE_MASTER]
	  ADD [AGE_MINIMUM] INT NULL
	, [AGE_MAXIMUM] INT NULL
	;

GO

-- End of 01) DACS-2252 - alter table CHARGE_MASTER - add age min max fields.SQL
GO

-- Start of 01) DACS-2402 - update description field of PHYSICIAN_SERVICE table where cat 331, guideline 8 risk categories.sql

------------------------------------------------------
-- 01) DACS-2402 - update description field of PHYSICIAN_SERVICE table where cat 331, guideline 8 risk categories.sql
-- Does NOT have to follow normal ACS workflow.  Can be executed on production databases when approved.
------------------------------------------------------
GO

/*
-------------------------------------------
previous message
	<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>
change to new message:
	<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter, dosage changes to current prescriptions, instructions to<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; stop taking a prescription medication, and prescription medications considered but ultimately not given)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>

Expect 14 records to be updated.
	
For DBAs should they need such:
	
SELECT TOP (100) *
FROM 
	[RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
where 
	[PHYSICIAN_SERVICE_GUIDELINE_ID] = 8
	AND [DESCRIPTION] LIKE '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (%'
	AND PLAN_ID = 1
	AND CATEGORY_ID = 3
	AND SUBCATEGORY_ID = 3
	AND MINOR_CATEGORY = 1
	AND (EFFECTIVE_DATE = '2022-09-01' AND EXPIRATION_DATE = '2099-12-31')	
	
-------------------------------------------
*/

UPDATE [RevCycleDB].[dbo].[PHYSICIAN_SERVICE]
	SET [DESCRIPTION] = '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (Prescriptions written at discharge; prescription strength meds<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; administered during encounter, dosage changes to current prescriptions, instructions to<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; stop taking a prescription medication, and prescription medications considered but ultimately not given)<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Minor Surgery <b>with</b> Identified Patient or Procedure Risk Factors<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Decision Regarding Elective Major Surgery <b>w/o</b> Identified Patient or Procedure Risk Factors <br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Diagnosis or Treatment Significantly Limited by Social Determinants of Health (Food and/or housing<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; insecurities, unemployment, lack of transportation etc.)<br>'
WHERE
	[PHYSICIAN_SERVICE_GUIDELINE_ID] = 8
	AND [DESCRIPTION] LIKE '<b>Moderate Risk of Morbidity from Additional Diagnostic Testing or Treatment</b><br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;•&nbsp;&nbsp;Prescription Drug Management (%'
	AND PLAN_ID = 1
	AND CATEGORY_ID = 3
	AND SUBCATEGORY_ID = 3
	AND MINOR_CATEGORY = 1
	AND (EFFECTIVE_DATE = '2022-09-01' AND EXPIRATION_DATE = '2099-12-31')

GO
-- End of 01) DACS-2402 - update description field of PHYSICIAN_SERVICE table where cat 331, guideline 8 risk categories.sql
GO

-- Start of 1) DACS-2264 Create Table ChargeMasterAutomationExcludeReason.sql

GO

CREATE TABLE [dbo].[ChargeMasterAutomationExcludeReason](
	[ChargeMasterAutomationExcludeReasonId] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[DateTimeExpiration] [datetime] NOT NULL,
	[DateTimeEffective] [datetime] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
 CONSTRAINT [PK_ChargeMasterAutomationExcludeReason] PRIMARY KEY CLUSTERED 
(
	[ChargeMasterAutomationExcludeReasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO
-- End of 1) DACS-2264 Create Table ChargeMasterAutomationExcludeReason.sql
GO

-- Start of 2) DACS-2264 Create Table ChargeMasterAutomationExclude.sql

GO

CREATE TABLE [dbo].[ChargeMasterAutomationExclude](
	[ChargeMasterAutomationExcludeId] [int] IDENTITY(1,1) NOT NULL,
	[ChargeMasterId] [int] NOT NULL,
	[ChargeMasterAutomationExcludeReasonId] [int] NOT NULL,
	[DateTimeExpiration] [datetime] NOT NULL,
	[DateTimeEffective] [datetime] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
 CONSTRAINT [PK_ChargeMasterAutomationExclude] PRIMARY KEY CLUSTERED 
(
	[ChargeMasterAutomationExcludeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude] ADD  CONSTRAINT [DF_ChargeMasterAutomationExclude_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude] ADD  CONSTRAINT [DF_ChargeMasterAutomationExclude_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude]  WITH CHECK ADD CONSTRAINT [FK_ChargeMasterAutomationExclude_ChargeMasterAutomationExcludeReason] FOREIGN KEY([ChargeMasterAutomationExcludeReasonId])
REFERENCES [dbo].[ChargeMasterAutomationExcludeReason] ([ChargeMasterAutomationExcludeReasonId])
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude]  WITH CHECK ADD CONSTRAINT [FK_ChargeMasterAutomationExclude_CHARGE_MASTER] FOREIGN KEY([ChargeMasterId])
REFERENCES [dbo].[CHARGE_MASTER] ([CHARGE_MASTER_ID])
GO
-- End of 2) DACS-2264 Create Table ChargeMasterAutomationExclude.sql
GO

-- Start of 3) DACS-2264 Create Procs for ChargeMasterAutomationExcludeReason.sql

GO

---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChargeMasterAutomationExcludeReason', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChargeMasterAutomationExcludeReason.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChargeMasterAutomationExcludeReason
END
GO

IF OBJECT_ID('dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
END
GO
IF OBJECT_ID('dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
END
GO

------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChargeMasterAutomationExcludeReason', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.InsertChargeMasterAutomationExcludeReason
	 @Description varchar(250)
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChargeMasterAutomationExcludeReasonId int OUTPUT
AS

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
(
	 [Description]
	,[DateTimeExpiration]
	,[DateTimeEffective]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @Description
	,@DateTimeExpiration
	,@DateTimeEffective
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ChargeMasterAutomationExcludeReasonId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
	 @ChargeMasterAutomationExcludeReasonId int
	,@Description varchar(250)
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
AS

UPDATE [dbo].[ChargeMasterAutomationExcludeReason] SET
	 [Description] = @Description
	,[DateTimeExpiration] = @DateTimeExpiration
	,[DateTimeEffective] = @DateTimeEffective
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
WHERE
	[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId
	@ChargeMasterAutomationExcludeReasonId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExcludeReason]
WHERE
	[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeReasonByChargeMasterAutomationExcludeReasonId]
	@ChargeMasterAutomationExcludeReasonId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChargeMasterAutomationExcludeReason].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExcludeReason].[Description]
	,[ChargeMasterAutomationExcludeReason].[DateTimeExpiration]
	,[ChargeMasterAutomationExcludeReason].[DateTimeEffective]
	,[ChargeMasterAutomationExcludeReason].[DateTimeCreated]
	,[ChargeMasterAutomationExcludeReason].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExcludeReason].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExcludeReason].[LastUpdatedByUserProfileId]
FROM
	[dbo].[ChargeMasterAutomationExcludeReason]
WHERE
	[ChargeMasterAutomationExcludeReason].[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId

GO	
		
-- End of 3) DACS-2264 Create Procs for ChargeMasterAutomationExcludeReason.sql
GO

-- Start of 4) DACS-2264 Create Procs for ChargeMasterAutomationExclude.sql

GO

---------------------------------------------------------------------------------
-- Drop stored procedures
---------------------------------------------------------------------------------
RAISERROR('Dropping existing stored procedures:', 0, 1) WITH NOWAIT;

IF OBJECT_ID('dbo.InsertChargeMasterAutomationExclude', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.InsertChargeMasterAutomationExclude.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.InsertChargeMasterAutomationExclude
END
GO

IF OBJECT_ID('dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
END
GO
IF OBJECT_ID('dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId.', 0, 1) WITH NOWAIT;
	DROP PROCEDURE dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
END
GO

IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]
END
GO
IF OBJECT_ID('[dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]', 'P') IS NOT NULL 
BEGIN
	RAISERROR('...dropping [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId].', 0, 1) WITH NOWAIT;
	DROP PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]
END
GO
------------------------------------------------------------------
-- Insert
------------------------------------------------------------------
RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertChargeMasterAutomationExclude', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.InsertChargeMasterAutomationExclude
	 @ChargeMasterId int
	,@ChargeMasterAutomationExcludeReasonId int
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
	,@ChargeMasterAutomationExcludeId int OUTPUT
AS

INSERT INTO [dbo].[ChargeMasterAutomationExclude]
(
	 [ChargeMasterId]
	,[ChargeMasterAutomationExcludeReasonId]
	,[DateTimeExpiration]
	,[DateTimeEffective]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @ChargeMasterId
	,@ChargeMasterAutomationExcludeReasonId
	,@DateTimeExpiration
	,@DateTimeEffective
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @ChargeMasterAutomationExcludeId = @@IDENTITY

GO

------------------------------------------------------------------
-- Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
	 @ChargeMasterAutomationExcludeId int
	,@ChargeMasterId int
	,@ChargeMasterAutomationExcludeReasonId int
	,@DateTimeExpiration datetime
	,@DateTimeEffective datetime
	,@CreatedByUserProfileId int
	,@LastUpdatedByUserProfileId int = NULL
AS

UPDATE [dbo].[ChargeMasterAutomationExclude] SET
	 [ChargeMasterId] = @ChargeMasterId
	,[ChargeMasterAutomationExcludeReasonId] = @ChargeMasterAutomationExcludeReasonId
	,[DateTimeExpiration] = @DateTimeExpiration
	,[DateTimeEffective] = @DateTimeEffective
	,[CreatedByUserProfileId] = @CreatedByUserProfileId
	,[DateTimeLastUpdated] = GETDATE()
	,[LastUpdatedByUserProfileId] = @LastUpdatedByUserProfileId
WHERE
	[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId
GO

------------------------------------------------------------------
--  Delete by primary key or unique index(es)
------------------------------------------------------------------

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE dbo.DeleteChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId
	@ChargeMasterAutomationExcludeId int
AS

DELETE 
	FROM [dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO

------------------------------------------------------------------
-- Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeId]
	@ChargeMasterAutomationExcludeId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	[dbo].[ChargeMasterAutomationExclude]
WHERE
	[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = @ChargeMasterAutomationExcludeId

GO	
		
------------------------------------------------------------------
--  Select by foreign key(s) or non-unique index(es)
------------------------------------------------------------------
RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterAutomationExcludeReasonId]
	 @ChargeMasterAutomationExcludeReasonId int
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
	[ChargeMasterAutomationExcludeId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChargeMasterAutomationExcludeId) ' +
		   'SELECT [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] ' +
		   'FROM [ChargeMasterAutomationExclude] ' +
		   'WHERE [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId] = ' + CAST(@ChargeMasterAutomationExcludeReasonId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChargeMasterAutomationExclude].[DateTimeCreated] '

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
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	#tmp [tmp]
	INNER JOIN [ChargeMasterAutomationExclude] 
			ON [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = [tmp].[ChargeMasterAutomationExcludeId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

RAISERROR('...creating [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]', 0, 1) WITH NOWAIT;

GO
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectChargeMasterAutomationExcludeByChargeMasterId]
	 @ChargeMasterId int
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
	[ChargeMasterAutomationExcludeId] int NOT NULL
)

DECLARE @sql nvarchar(2000)

SET @sql = 'INSERT INTO #tmp (ChargeMasterAutomationExcludeId) ' +
		   'SELECT [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] ' +
		   'FROM [ChargeMasterAutomationExclude] ' +
		   'WHERE [ChargeMasterAutomationExclude].[ChargeMasterId] = ' + CAST(@ChargeMasterId AS VARCHAR(10)) 

IF @WhereClause IS NOT NULL AND LEN(@WhereClause) > 0
	SET @sql = @sql + ' AND (' + @WhereClause + ') '

IF @OrderByClause IS NOT NULL AND LEN(@OrderByClause) > 0
	SET @sql = @sql + 'ORDER BY ' + @OrderByClause + ' '
ELSE
	SET @sql = @sql + 'ORDER BY [ChargeMasterAutomationExclude].[DateTimeCreated] '

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
	 [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId]
	,[ChargeMasterAutomationExclude].[ChargeMasterId]
	,[ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeReasonId]
	,[ChargeMasterAutomationExclude].[DateTimeExpiration]
	,[ChargeMasterAutomationExclude].[DateTimeEffective]
	,[ChargeMasterAutomationExclude].[DateTimeCreated]
	,[ChargeMasterAutomationExclude].[CreatedByUserProfileId]
	,[ChargeMasterAutomationExclude].[DateTimeLastUpdated]
	,[ChargeMasterAutomationExclude].[LastUpdatedByUserProfileId]
FROM
	#tmp [tmp]
	INNER JOIN [ChargeMasterAutomationExclude] 
			ON [ChargeMasterAutomationExclude].[ChargeMasterAutomationExcludeId] = [tmp].[ChargeMasterAutomationExcludeId]
WHERE
	[tmp].[IndexId] BETWEEN @FirstRecord AND @LastRecord
ORDER BY
	[tmp].[IndexId]

GO

-- End of 4) DACS-2264 Create Procs for ChargeMasterAutomationExclude.sql
GO

-- Start of 5) DACS-2264 Insert Rows ChargeMasterAutomationExcludeReason.sql

GO

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
           ([Description]
           ,[DateTimeExpiration]
           ,[DateTimeEffective]
           ,[DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId])
     VALUES
           ('Low Confidence'
           ,'12/31/2099'
           ,'06/01/2023'
           ,'06/01/2023'
           , 10037
           ,'06/01/2023'
           , 10037);

INSERT INTO [dbo].[ChargeMasterAutomationExcludeReason]
           ([Description]
           ,[DateTimeExpiration]
           ,[DateTimeEffective]
           ,[DateTimeCreated]
           ,[CreatedByUserProfileId]
           ,[DateTimeLastUpdated]
           ,[LastUpdatedByUserProfileId])
     VALUES
           ('Not Charged by Facility'
           ,'12/31/2099'
           ,'06/01/2023'
           ,'06/01/2023'
           , 10037
           ,'06/01/2023'
           , 10037);
-- End of 5) DACS-2264 Insert Rows ChargeMasterAutomationExcludeReason.sql
GO

-- Check for errors and commit/rollback the transaction
IF @@TRANCOUNT > 0
BEGIN
    IF XACT_STATE() = 1
    BEGIN
        COMMIT TRANSACTION
        PRINT 'Transaction committed.'
    END
    ELSE IF XACT_STATE() = -1
    BEGIN
        ROLLBACK TRANSACTION
        PRINT 'Transaction rolled back due to an error.'
    END
END
GO
