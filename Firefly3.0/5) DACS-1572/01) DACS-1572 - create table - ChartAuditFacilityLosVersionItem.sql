------------------------------------------------------
-- 01) DACS-1572 - create table - ChartAuditFacilityLosVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ChartAuditFacilityLosVersionItem](
	-- Base table structure
	[ChartAuditFacilityLosVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditFacilityLosVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	-- Exclusion information
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	-- Particular to Demographic Audit fields
	[ChartId] [int] NULL,  -- Key field
	[LevelNumber] [int] NULL, -- Key field
	[CptCode] [varchar](10) NULL,
	[Modifier] [varchar](100) NULL,
	[FacilityChartId] [varchar](20) NULL,
	[FacilityLevelId] [int] NULL,
	[OverrideFacilityLevelId] [int] NULL,


CONSTRAINT [PK_ChartAuditFacilityLosVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditFacilityLosVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditFacilityLosVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosVersionItem] CHECK CONSTRAINT [FK_ChartAuditFacilityLosVersionItem_ChartAuditVersion]
GO


-- if table needs to be removed: DROP TABLE [dbo].[ChartAuditFacilityLosVersionItem];