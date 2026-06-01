USE [RevCycleDB]
GO

CREATE TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem](
	[ChartAuditPhysicianLosEvalVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditPhysicianLosVersionItemId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditPhysicianLosEvalVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	[ChartId] [int] NOT NULL,
	[LevelNbr] [int] NOT NULL,
	[PhysicianServiceId] [int] NULL,
	[PlanId] [int] NULL,
	[CategoryId] [int] NULL,
	[SubcategoryId] [int] NULL,
	[MinorCategoryId] [int] NULL,
	[ServiceDescription] [varchar](100) NULL,
	[Quantity] [int] NULL,
	[Points]  [int] NULL
 CONSTRAINT [PK_ChartAuditPhysicianLosEvalVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditPhysicianLosEvalVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosEvalVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditPhysicianLosEvalVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditPhysicianLosEvalVersionItem_ChartAuditPhysicianLosVersionItem] FOREIGN KEY([ChartAuditPhysicianLosVersionItemId])
REFERENCES [dbo].[ChartAuditPhysicianLosVersionItem] ([ChartAuditPhysicianLosVersionItemId])
GO

ALTER TABLE [dbo].[ChartAuditPhysicianLosEvalVersionItem] CHECK CONSTRAINT [FK_ChartAuditPhysicianLosEvalVersionItem_ChartAuditPhysicianLosVersionItem]
GO