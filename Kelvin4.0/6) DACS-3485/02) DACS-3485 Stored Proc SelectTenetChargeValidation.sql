---------------------------------------------------------------------------------------------------------------------
-- 02) DACS-3485 - Stored Procedure [dbo].[SelectTenetChargeValidation] to select all TenetChargeValidation
---------------------------------------------------------------------------------------------------------------------

USE [RevCycleDB]
GO

CREATE PROCEDURE [dbo].[SelectTenetChargeValidation]
AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	[TenetChargeValidationId],
	[PatientId],
	[BillingCode],
	[CPTCode],
	[TenetChargeId],
	[CreationDateTime]
FROM
	[TenetChargeValidation]

GO
