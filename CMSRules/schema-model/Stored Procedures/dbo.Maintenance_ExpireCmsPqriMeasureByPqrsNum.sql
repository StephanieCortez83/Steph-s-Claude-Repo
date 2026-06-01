SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[Maintenance_ExpireCmsPqriMeasureByPqrsNum]
@PqrsNum VARCHAR(20)
, @ExpireDate DATE
, @SkipDateNullCheck BIT = 0
AS
BEGIN
SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
IF @PqrsNum IS NULL OR LEN(@PqrsNum) <= 0
BEGIN
SELECT 'ERROR' = '@PqrsNum is invalid';
RETURN;
END;
IF @ExpireDate IS NULL
BEGIN
SELECT 'ERROR' = '@ExpireDate is invalid';
RETURN;
END;
IF @SkipDateNullCheck = 1
UPDATE [CMSRules].[dbo].[CMS_PQRI_MEASURE]
SET [EXPIRATION_DATE] = @ExpireDate
WHERE
[PQRS#] = @PqrsNum
ELSE
UPDATE [CMSRules].[dbo].[CMS_PQRI_MEASURE]
SET [EXPIRATION_DATE] = @ExpireDate
WHERE
[PQRS#] = @PqrsNum
AND [EXPIRATION_DATE] IS NULL
DECLARE @countResult INT = (SELECT Count (*) FROM [CMSRules].[dbo].
[CMS_PQRI_MEASURE] WHERE [PQRS#] = @PqrsNum AND [EXPIRATION_DATE] = @ExpireDate)
SELECT 'RESULT' = 'CMS PQRS Measure [' + @PqrsNum + '] expired to [' +
CAST(@ExpireDate AS VARCHAR(30)) + '] count = ' + CAST(@countResult AS
VARCHAR(30));
END
GO
