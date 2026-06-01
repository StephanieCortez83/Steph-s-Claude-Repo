------------------------------------------------------------------
-- 06) DACS-3485 - Update
------------------------------------------------------------------
RAISERROR('Creating update stored procedure(s):', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.UpdateByTenetChargeValidationByTenetChargeValidationId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.UpdateByTenetChargeValidationByTenetChargeValidationId
	 @TenetChargeValidationId int
	,@PatientId varchar(20)
	,@BillingCode varchar(20)
	,@CPTCode varchar(5)
	,@TenetChargeId int
	,@CreationDateTime datetime
AS

UPDATE [dbo].[TenetChargeValidation] SET
	 [PatientId] = @PatientId
	,[BillingCode] = @BillingCode
	,[CPTCode] = @CPTCode
	,[TenetChargeId] = @TenetChargeId
	,[CreationDateTime] = @CreationDateTime
WHERE
	[TenetChargeValidationId] = @TenetChargeValidationId
GO
