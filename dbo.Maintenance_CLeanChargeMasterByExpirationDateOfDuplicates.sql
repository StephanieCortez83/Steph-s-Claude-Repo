SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Maintenance_CLeanChargeMasterByExpirationDateOfDuplicates]
	  @ErrantDate DATETIME = '10/11/2023'
	, @SAId INT
	, @ExpectedCountDelete INT = 272
	, @TestMode INT = 0
AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	DECLARE @TestCount INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND EFFECTIVE_DATE = @ErrantDate);

	IF (@TestCount = @ExpectedCountDelete AND @TestMode = 0)
	BEGIN
		DELETE FROM CHARGE_MASTER 
		WHERE
			SERVICE_AGREEMENT_ID = @SAId
			AND EFFECTIVE_DATE = @ErrantDate
	END
	ELSE
	BEGIN
		PRINT('Expected deletion count does not match returned value : [' + CAST(@ExpectedCountDelete as VARCHAR(50)) + ':' + CAST(@TestCount as VARCHAR(50)) + '].')
	END


	SET @TestCount = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND EXPIRATION_DATE = @ErrantDate);
	PRINT('Expected Update count = : [' + CAST(@TestCount as VARCHAR(50)) + '].')
	
	IF @TestMode = 1
	BEGIN
		return;
	END;


	UPDATE CHARGE_MASTER
	SET EXPIRATION_DATE = '12/31/2099'
	WHERE 
		SERVICE_AGREEMENT_ID = @SAId
--		AND EXPIRATION_DATE = @ErrantDate;

GO
