USE [RevCycleDB]
GO

CREATE TABLE [dbo].[ChargeMasterAutomationExclude](
	[ChargeMasterAutomationExcludeId] [int] IDENTITY(1,1) NOT NULL,
	[ChargeMasterId] [int] NOT NULL,
	[ChargeMasterAutomationExcludeReasonId] [int] NOT NULL,
	[DateTimeExpiration] [datetime] NOT NULL,
	[DateTimeEffective] [datetime] NOT NULL,
	[DateTimeCreated] [datetime] NOT NULL,
	[CreatedByUserProfileId] [int] NOT NULL,
	[DateTimeLastUpdated] [datetime] NOT NULL,
	[LastUpdatedByUserProfileId] [int] NULL,
 CONSTRAINT [PK_ChargeMasterAutomationExclude] PRIMARY KEY CLUSTERED 
(
	[ChargeMasterAutomationExcludeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [FGData1]
) ON [FGData1]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude] ADD  CONSTRAINT [DF_ChargeMasterAutomationExclude_DateTimeCreated]  DEFAULT (getdate()) FOR [DateTimeCreated]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude] ADD  CONSTRAINT [DF_ChargeMasterAutomationExclude_DateTimeLastUpdated]  DEFAULT (getdate()) FOR [DateTimeLastUpdated]
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude]  WITH CHECK ADD CONSTRAINT [FK_ChargeMasterAutomationExclude_ChargeMasterAutomationExcludeReason] FOREIGN KEY([ChargeMasterAutomationExcludeReasonId])
REFERENCES [dbo].[ChargeMasterAutomationExcludeReason] ([ChargeMasterAutomationExcludeReasonId])
GO

ALTER TABLE [dbo].[ChargeMasterAutomationExclude]  WITH CHECK ADD CONSTRAINT [FK_ChargeMasterAutomationExclude_CHARGE_MASTER] FOREIGN KEY([ChargeMasterId])
REFERENCES [dbo].[CHARGE_MASTER] ([CHARGE_MASTER_ID])
GO