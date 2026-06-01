USE [RevCycleDB]
GO

CREATE TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem](
	[ChartAuditFacilityLosEvalVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditFacilityLosVersionItemId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ActionDescription] [varchar](250) NULL,
	[PrevChartAuditFacilityLosEvalVersionItemId] [int] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
	[ChartId] [int] NULL,
	[FacilityServiceId] [int] NULL,
	[FacilityServiceDescription] [varchar](75) NULL,
	[Points] [int] NULL
 CONSTRAINT [PK_ChartAuditFacilityLosEvalVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditFacilityLosEvalVersionItemId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosEvalVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] ADD  CONSTRAINT [DF_ChartAuditFacilityLosEvalVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditFacilityLosEvalVersionItem_ChartAuditFacilityLosVersionItem] FOREIGN KEY([ChartAuditFacilityLosVersionItemId])
REFERENCES [dbo].[ChartAuditFacilityLosVersionItem] ([ChartAuditFacilityLosVersionItemId])
GO

ALTER TABLE [dbo].[ChartAuditFacilityLosEvalVersionItem] CHECK CONSTRAINT [FK_ChartAuditFacilityLosEvalVersionItem_ChartAuditFacilityLosVersionItem]
GO