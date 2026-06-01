----------------------------------------
-- 01) DACS-2991 - Create Table - UserGroupReportAccess.SQL
----------------------------------------
USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[UserGroupReportAccess](
	[UserGroupReportAccessId] [int] IDENTITY(1,1) NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
	[UserGroupId] [int] NOT NULL,
	[ReportName] VARCHAR(256),
	[EffectiveDate] [datetime] NOT NULL,
	[ExpirationDate] [datetime] NULL
 CONSTRAINT [PK_UserGroupReportAccess] PRIMARY KEY CLUSTERED 
(
	[UserGroupReportAccessId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[UserGroupReportAccess] ADD  CONSTRAINT [DF_UserGroupReportAccess_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[UserGroupReportAccess] ADD  CONSTRAINT [DF_UserGroupReportAccess_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO
