CREATE TABLE [dbo].[ChartAuditVersion](
	[ChartAuditVersionId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[VersionNumber] [int] NOT NULL,
	[PreviousChartAuditVersionId] [int] NULL,
 CONSTRAINT [PK_ChartAuditVersion] PRIMARY KEY CLUSTERED 
(
	[ChartAuditVersionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditVersion] ADD  CONSTRAINT [DF_ChartAuditVersion_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditVersion] ADD  CONSTRAINT [DF_ChartAuditVersion_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChartAuditVersion]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditVersion_ChartAudit] FOREIGN KEY([ChartAuditId])
REFERENCES [dbo].[ChartPostBillAudit] ([ChartPostBillAuditId])
GO

ALTER TABLE [dbo].[ChartAuditVersion] CHECK CONSTRAINT [FK_ChartAuditVersion_ChartAudit]
GO
CREATE NONCLUSTERED INDEX [IX_ChartAuditVersion_ChartAuditId] ON [dbo].[ChartAuditVersion]
(
	[ChartAuditId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
