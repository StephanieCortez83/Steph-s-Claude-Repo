------------------------------------------------------
-- 01) DACS-1570 - create table - ChartAuditPhysicianLosVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ChartAuditPhysicianLosVersionItem](
	-- Base table structure
	[ChartAuditPhysicianLosVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditPhysicianLosVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	-- Exclusion information
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	-- Particular to Demographic Audit fields
	[ChartId] [int] NULL,
	[LevelNumber] [int] NULL,
	[DateOfService] [datetime] NULL,
	[PhysicianHistoryId] [int] NULL,
	[PhysicianHistoryDescription] [varchar](250) NULL,
	[PhysicianExamId] [int] NULL,
	[PhysicianExamDescription] [varchar](250) NULL,
	[PhysicianMdmId] [int] NULL,
	[PhysicianMdmDescription] [varchar](250) NULL,
	[PhysicianServiceProcId] [int] NULL,
	[OverridePhysicianServiceProcId] [int] NULL,
	[CptCode] [varchar](10) NULL,
	[Modifier] [varchar](100) NULL,
	[ProviderId] [int] NULL,
	
CONSTRAINT [PK_ChartAuditPhysicianLosVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditPhysicianLosVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditPhysicianLosVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosVersionItem] CHECK CONSTRAINT [FK_ChartAuditPhysicianLosVersionItem_ChartAuditVersion]
GO


-- if table needs to be removed: DROP TABLE [dbo].[ChartAuditPhysicianLosVersionItem];