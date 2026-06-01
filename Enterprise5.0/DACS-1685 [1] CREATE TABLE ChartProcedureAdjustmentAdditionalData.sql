USE [RevCycleDB]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ChartProcedureAdjustmentAdditionalData]
(
	[ChartProcedureAdjustmentAdditionalDataId] 	[INT] 		IDENTITY(1,1) 	NOT NULL
   ,[DateTimeCreated] 							[DATETIME] 					NOT NULL
   ,[CreatedByUserProfileId] 					[INT] 						NULL
   ,[DateTimeLastUpdated] 						[DATETIME] 					NOT NULL
   ,[LastUpdatedByUserProfileId] 				[INT] 						NULL
   ,[ChartId]									[INT] 						NOT NULL
   ,[PatientClassId]							[INT] 						NOT NULL
   ,CONSTRAINT 
   		[PK_ChartProcedureAdjustmentAdditionalData] 
	PRIMARY KEY CLUSTERED 
	(
		[ChartProcedureAdjustmentAdditionalDataId] ASC
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

-- Add default value for DateTimeCreated
ALTER TABLE
	[dbo].[ChartProcedureAdjustmentAdditionalData]
ADD CONSTRAINT
	[DF_ChartProcedureAdjustmentAdditionalData_DateTimeCreated]
DEFAULT (GETDATE()) FOR [DateTimeCreated]
GO

-- Add default value for DateTimeLastUpdated
ALTER TABLE
	[dbo].[ChartProcedureAdjustmentAdditionalData]
ADD CONSTRAINT
	[DF_ChartProcedureAdjustmentAdditionalData_DateTimeLastUpdated]
DEFAULT (GETDATE()) FOR [DateTimeLastUpdated]
GO

-- Add foreign key FK_ChartProcedureAdjustmentAdditionalData_CHART
ALTER TABLE 
	[dbo].[ChartProcedureAdjustmentAdditionalData] WITH CHECK 
ADD CONSTRAINT 
	[FK_ChartProcedureAdjustmentAdditionalData_CHART] FOREIGN KEY([ChartId])
REFERENCES 
	[dbo].[CHART] ([CHART_ID])
GO

-- Add check constraint FK_ChartProcedureAdjustmentAdditionalData_CHART
ALTER TABLE 
	[dbo].[ChartProcedureAdjustmentAdditionalData] 
CHECK CONSTRAINT 
	[FK_ChartProcedureAdjustmentAdditionalData_CHART]
GO


