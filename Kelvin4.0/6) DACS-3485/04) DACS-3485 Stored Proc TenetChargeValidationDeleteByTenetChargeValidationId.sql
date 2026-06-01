------------------------------------------------------------------
-- 04) DACS-3485 - Delete by primary key or unique index(es)
------------------------------------------------------------------
USE [RevCycleDB]
GO

RAISERROR('Creating delete stored procedure:', 0, 1) WITH NOWAIT;
RAISERROR('...creating dbo.DeleteTenetChargeValidationByTenetChargeValidationId', 0, 1) WITH NOWAIT;

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE dbo.DeleteTenetChargeValidationByTenetChargeValidationId
	@TenetChargeValidationId int
AS

DELETE 
	FROM [dbo].[TenetChargeValidation]
WHERE
	[TenetChargeValidationId] = @TenetChargeValidationId

GO