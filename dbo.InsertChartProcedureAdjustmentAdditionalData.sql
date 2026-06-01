SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertChartProcedureAdjustmentAdditionalData]
	 @CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@ChartId int
	,@PatientClassId int
	,@ChartProcedureAdjustmentAdditionalDataId int OUTPUT
AS

INSERT INTO [dbo].[ChartProcedureAdjustmentAdditionalData]
(
	 [CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
	,[ChartId]
	,[PatientClassId]
)
VALUES
(
	 @CreatedByUserProfileId
	,@LastUpdatedByUserProfileId
	,@ChartId
	,@PatientClassId 
)

SET @ChartProcedureAdjustmentAdditionalDataId = @@IDENTITY

GO
