USE [RevCycleDB]
GO

CREATE TABLE [dbo].[ChargeMasterAutomationExcludeReason](
	[ChargeMasterAutomationExcludeReasonId] [int] IDENTITY(1,1) NOT NULL,
	[Description] [varchar](250) NOT NULL,
	[DateTimeExpiration] [datetime] NOT NULL,
	[DateTimeEffective] [datetime] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
 CONSTRAINT [PK_ChargeMasterAutomationExcludeReason] PRIMARY KEY CLUSTERED 
(
	[ChargeMasterAutomationExcludeReasonId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO