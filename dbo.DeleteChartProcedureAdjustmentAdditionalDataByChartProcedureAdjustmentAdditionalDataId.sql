SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteChartProcedureAdjustmentAdditionalDataByChartProcedureAdjustmentAdditionalDataId]
	@ChartProcedureAdjustmentAdditionalDataId int
AS

DELETE 
	FROM [dbo].[ChartProcedureAdjustmentAdditionalData]
WHERE
	[ChartProcedureAdjustmentAdditionalDataId] = @ChartProcedureAdjustmentAdditionalDataId

GO
