USE [RevCycleDB]
GO

CREATE TABLE [dbo].[ChartAuditActionTypeCode](
	[ChartAuditActionTypeCode] [int] NOT NULL,
	[Key] [varchar](100) NOT NULL,
	[DisplayName] [varchar](120) NULL,
	[ExternalCode] [varchar](120) NULL,
	[Description] [varchar](500) NULL,
 CONSTRAINT [PK_ChartAuditActionTypeCode] PRIMARY KEY CLUSTERED 
(
	[ChartAuditActionTypeCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO
