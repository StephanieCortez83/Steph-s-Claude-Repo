USE [RevCycleDB]
GO

-- Create nonclustered index on FGIndex1
CREATE UNIQUE NONCLUSTERED INDEX 
	[IX_ChartProcedureAdjustmentAdditionalData_ChartId] 
ON 
	[dbo].[ChartProcedureAdjustmentAdditionalData]
(
	[ChartId] ASC
) ON [FGIndex1]

GO


