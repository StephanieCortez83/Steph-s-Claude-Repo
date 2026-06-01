SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[DeleteServiceAgreementPqrsByServiceAgreementId] 
	 @ServiceAgreementId INT
WITH EXEC AS CALLER AS
BEGIN
	-------------------------------
	-- setup resources
	-------------------------------
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @ServiceAgreementId IS NOT NULL AND @ServiceAgreementId > 0 AND EXISTS (SELECT TOP 1 1 FROM [dbo].[SERVICE_AGREEMENT_PQRS] WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId) 
	BEGIN
		PRINT ('Calling delete for Said = ' + CAST(@ServiceAgreementId AS VARCHAR(32)));
		DELETE FROM [dbo].[SERVICE_AGREEMENT_PQRS] WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
		SELECT COUNT(SERVICE_AGREEMENT_ID) AS 'RESULT' FROM [dbo].[SERVICE_AGREEMENT_PQRS] WHERE [SERVICE_AGREEMENT_ID] = @ServiceAgreementId;
		RETURN;
	END;

	PRINT ('No action performed for Said = ' + CAST(IIF(@ServiceAgreementId IS NULL, -911, @ServiceAgreementId) AS VARCHAR(32)));
	SELECT 'RESULT' = -1;

/*
-use example:
begin tran;
exec [dbo].[DeleteServiceAgreementPqrsByServiceAgreementId] @ServiceAgreementId = -1
-- exec [dbo].[DeleteServiceAgreementPqrsByServiceAgreementId] @ServiceAgreementId = null
-- rollback tran;
-- commit tran;
*/
END -- end procedure

GO
