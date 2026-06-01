------------------------------------------------------
-- 01) DACS-1674 - create table - ChartAuditDocumentationVersionItem.sql
------------------------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ChartAuditDocumentationVersionItem](
	-- Base table structure
	[ChartAuditDocumentationVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditDocumentationVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	-- Exclusion information
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	-- Particular to Documentation Audit fields
	[DocumentationId] [int] NULL,
	[DocumentationDeficiencyId] [int] NULL,
	[DocumentationChecked] [bit] NULL
CONSTRAINT [PK_ChartAuditDocumentationVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditDocumentationVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] ADD  CONSTRAINT [DF_ChartAuditDocumentationVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] ADD  CONSTRAINT [DF_ChartAuditDocumentationVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditDocumentationVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditDocumentationVersionItem] CHECK CONSTRAINT [FK_ChartAuditDocumentationVersionItem_ChartAuditVersion]
GO


-- if table needs to be removed: DROP TABLE [dbo].[ChartAuditDocumentationVersionItem];