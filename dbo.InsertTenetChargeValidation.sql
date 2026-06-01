SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertTenetChargeValidation]
	 @ChartId int
	,@BillingCode varchar(20)
	,@CPTCode varchar(5)
	,@TenetChargeId varchar(30)
	,@CreatedByUserProfileId int = NULL
	,@LastUpdatedByUserProfileId int = NULL
	,@TenetChargeValidationId int OUTPUT
AS

INSERT INTO [dbo].[TenetChargeValidation]
(
	 [ChartId]
	,[BillingCode]
	,[CPTCode]
	,[TenetChargeId]
	,[CreatedByUserProfileId]
	,[LastUpdatedByUserProfileId]
)
VALUES
(
	 @ChartId
	,@BillingCode
	,@CPTCode
	,@TenetChargeId
	,@CreatedByUserProfileId
	,@LastUpdatedByUserProfileId 
)

SET @TenetChargeValidationId = @@IDENTITY

GO
