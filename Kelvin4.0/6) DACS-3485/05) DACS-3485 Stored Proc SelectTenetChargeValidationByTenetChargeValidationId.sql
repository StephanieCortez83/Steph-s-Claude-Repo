------------------------------------------------------------------
-- 05) DACS-3485 - Select Sprocs by primary key or unique indexes
------------------------------------------------------------------
USE [RevCycleDB]
GO

RAISERROR('Creating select stored procedures:', 0, 1) WITH NOWAIT;

RAISERROR('...creating [dbo].[SelectTenetChargeValidationByTenetChargeValidationId]', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[SelectTenetChargeValidationByTenetChargeValidationId]
	@TenetChargeValidationId int
AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 [TenetChargeValidation].[TenetChargeValidationId]
	,[TenetChargeValidation].[PatientId]
	,[TenetChargeValidation].[BillingCode]
	,[TenetChargeValidation].[CPTCode]
	,[TenetChargeValidation].[TenetChargeId]
	,[TenetChargeValidation].[CreationDateTime]
FROM
	[dbo].[TenetChargeValidation]
WHERE
	[TenetChargeValidation].[TenetChargeValidationId] = @TenetChargeValidationId

GO	
