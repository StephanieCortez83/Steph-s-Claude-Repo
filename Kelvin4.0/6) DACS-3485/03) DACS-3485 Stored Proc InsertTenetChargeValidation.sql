------------------------------------------------------------------
-- 03) DACS-3485 - Insert
------------------------------------------------------------------

USE [RevCycleDB]
GO

RAISERROR('Creating insert stored procedures:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.InsertTenetChargeValidation', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.InsertTenetChargeValidation
	 @PatientId varchar(20)
	,@BillingCode varchar(20)
	,@CPTCode varchar(5)
	,@TenetChargeId int
	,@CreationDateTime datetime
	,@TenetChargeValidationId int OUTPUT
AS

INSERT INTO [dbo].[TenetChargeValidation]
(
	 [PatientId]
	,[BillingCode]
	,[CPTCode]
	,[TenetChargeId]
	,[CreationDateTime]
)
VALUES
(
	 @PatientId
	,@BillingCode
	,@CPTCode
	,@TenetChargeId
	,@CreationDateTime 
)

SET @TenetChargeValidationId = @@IDENTITY

GO