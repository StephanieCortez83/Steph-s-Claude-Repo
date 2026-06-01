Use [RevCycleDB]
GO

Drop TABLE [dbo].[ChartAuditAnesthesiaVersionItem]
GO

CREATE TABLE [dbo].[ChartAuditAnesthesiaVersionItem]
(
    [ChartAuditAnesthesiaVersionItemId]     [INT] IDENTITY(1,1) NOT NULL
   ,[ChartAuditVersionId]                   [INT]               NOT NULL
   ,[DateTimeCreated]                       [DATETIME]          NOT NULL
   ,[CreatedByUserProfileId]                [INT]               NOT NULL
   ,[DateTimeLastUpdated]                   [DATETIME]          NOT NULL
   ,[LastUpdatedByUserProfileId]            [INT]               NULL
   ,[ChartAuditActionTypeCode]              [INT]               NOT NULL
   ,[ActionDescription]                     [VARCHAR](250)      NULL
   ,[PrevChartAuditAnesthesiaVersionItemId] [INT]               NULL
   ,[IsPreviousVersionCorrect]              [BIT]               NOT NULL
   ,[ExcludeFromQA]                         [BIT]               NOT NULL
   ,[ExcludeFromQAReasonID]                 [INT]               NULL
   ,[AnesthesiaCode]						[VARCHAR](10)		NULL
   ,CONSTRAINT 
        [PK_ChartAuditAnesthesiaVersionItem] 
    PRIMARY KEY CLUSTERED
    (
        [ChartAuditAnesthesiaVersionItemId] ASC
    )
    WITH 
    (
        PAD_INDEX = OFF
       ,STATISTICS_NORECOMPUTE = OFF
       ,IGNORE_DUP_KEY = OFF
       ,ALLOW_ROW_LOCKS = ON
       ,ALLOW_PAGE_LOCKS = ON
    ) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE 
    [dbo].[ChartAuditAnesthesiaVersionItem] 
ADD CONSTRAINT 
    [DF_ChartAuditAnesthesiaVersionItem_DateTimeCreated]
DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE 
    [dbo].[ChartAuditAnesthesiaVersionItem] 
ADD CONSTRAINT 
    [DF_ChartAuditAnesthesiaVersionItem_DateTimeLastUpdated]
DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE 
    [dbo].[ChartAuditAnesthesiaVersionItem] WITH CHECK 
ADD CONSTRAINT 
    [FK_ChartAuditAnesthesiaVersionItem_ChartAuditVersion] FOREIGN KEY([ChartAuditVersionId])
REFERENCES 
    [dbo].[ChartAuditVersion] ([ChartAuditVersionId])
GO

ALTER TABLE 
    [dbo].[ChartAuditAnesthesiaVersionItem] 
CHECK CONSTRAINT 
    [FK_ChartAuditAnesthesiaVersionItem_ChartAuditVersion]
GO