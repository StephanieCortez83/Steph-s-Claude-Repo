----------------------------------------
-- 02) DACS-645 - Create Table - [dbo].[PhysicianServiceEvalDiagnosis].sql
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[PhysicianServiceEvalDiagnosis](
	[PhysicianServiceEvalDiagnosisId] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartId] [int] NOT NULL,
	[PhysicianServiceLevelNumber] [int] NOT NULL,
	[PhysicianServiceProcId] [int] NOT NULL,
	[CptCode] VARCHAR(10) NOT NULL,
	[Icd10Codes] VARCHAR(128) NOT NULL, -- can be comma delimited list
	[Modifiers] VARCHAR(128) NOT NULL, -- can be comma delimited list
	[DateOfService] DATETIME NULL,
 CONSTRAINT [PK_PhysicianServiceEvalDiagnosis] PRIMARY KEY CLUSTERED 
(
	[PhysicianServiceEvalDiagnosisId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[PhysicianServiceEvalDiagnosis] ADD  CONSTRAINT [DF_PhysicianServiceEvalDiagnosis_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[PhysicianServiceEvalDiagnosis] ADD  CONSTRAINT [DF_PhysicianServiceEvalDiagnosis_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO


