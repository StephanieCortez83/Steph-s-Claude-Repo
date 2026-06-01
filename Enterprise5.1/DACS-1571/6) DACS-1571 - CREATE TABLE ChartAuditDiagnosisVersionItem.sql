CREATE TABLE [dbo].[ChartAuditDiagnosisVersionItem](
	[ChartAuditDiagnosisVersionItemId] [int] IDENTITY(1,1) NOT NULL,
	[ChartAuditVersionId] [int] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[ChartAuditActionDescription] [varchar](1000) NULL,
	[DiagnosisTypeDescription] [varchar](100) NULL,
	[IsPrimary] [bit] NULL,
	[IsChiefComplaintChange] [bit] NULL,
	[IsPrimaryDiagnosisChange] [bit] NULL,
	[IsPreviousVersionCorrect] [bit] NULL,
	[ICDCode] [varchar](10) NOT NULL,
	[ICDCodeDescription] [varchar](250) NULL,
	[ICDPostingOrder] [int] NULL,
	[ExcludeFromQA] [bit] NULL,
	[ExcludeFromQAReasonID] [int] NULL,
CONSTRAINT [PK_ChartAuditDiagnosisVersionItem] PRIMARY KEY CLUSTERED 
(
	[ChartAuditDiagnosisVersionItemId] ASC
) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChartAuditDiagnosisVersionItem] ADD  CONSTRAINT [DF_ChartAuditDiagnosisVersionItem_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChartAuditDiagnosisVersionItem] ADD  CONSTRAINT [DF_ChartAuditDiagnosisVersionItem_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ChartAuditDiagnosisVersionItem_ChartAuditVersionId] ON [dbo].[ChartAuditDiagnosisVersionItem]
(
	[ChartAuditVersionId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGIndex1]
GO
ALTER TABLE [dbo].[ChartAuditDiagnosisVersionItem]  WITH CHECK ADD  CONSTRAINT [FK_ChartAuditDiagnosisVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE [dbo].[ChartAuditDiagnosisVersionItem] CHECK CONSTRAINT [FK_ChartAuditDiagnosisVersionItem_ChartAuditVersion]
GO
