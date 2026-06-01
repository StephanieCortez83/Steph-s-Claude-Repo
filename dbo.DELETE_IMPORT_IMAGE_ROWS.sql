SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[DELETE_IMPORT_IMAGE_ROWS]
@RowsPerIteration int, @ServiceAgreementID int, @OlderThanDate datetime, @RowsDeleted int OUTPUT
WITH 
EXECUTE AS CALLER
AS
SET NOCOUNT ON
DECLARE @RowsDeletedThisIteration int
SET @RowsDeletedThisIteration = 0
SET @RowsDeleted = 0
WHILE 1 = 1
BEGIN
DELETE TOP(@RowsPerIteration)
FROM IMPORT_IMAGE
WHERE SERVICE_AGREEMENT_ID = @ServiceAgreementID
AND CREATION_DATE_TIME < @OlderThanDate;

SET @RowsDeletedThisIteration = @@ROWCOUNT;
SET @RowsDeleted = @RowsDeleted + @RowsDeletedThisIteration;

IF @RowsDeletedThisIteration < @RowsPerIteration BREAK;
END
SET NOCOUNT OFF
GO
