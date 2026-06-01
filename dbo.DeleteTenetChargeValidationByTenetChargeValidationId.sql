SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteTenetChargeValidationByTenetChargeValidationId]
	@TenetChargeValidationId int
AS

DELETE 
	FROM [dbo].[TenetChargeValidation]
WHERE
	[TenetChargeValidationId] = @TenetChargeValidationId

GO
