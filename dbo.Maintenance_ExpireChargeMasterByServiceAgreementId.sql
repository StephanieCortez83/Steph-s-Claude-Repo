SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ExpireChargeMasterByServiceAgreementId]
      @SAId INT
	, @ExpireDate DATETIME = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SAId IS NULL OR @SAId <= 0
	BEGIN
		SELECT 'ERROR' = '@SAId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SET @ExpireDate = GETDATE();
	END;
	
	DECLARE @countCM  INT = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate));

	PRINT('@SAId  = ' + CAST(@SAId AS varchar(20)));
	PRINT('@ExpireDate  = ' + CAST(@ExpireDate AS varchar(40)));
	PRINT('Starting @countCM  = ' + CAST(@countCM AS varchar(20)));


	PRINT('------------------------------------------');
	PRINT('       Process Charge Master');
	PRINT('------------------------------------------');

	IF @countCM > 0
	BEGIN
		UPDATE CHARGE_MASTER 
			SET EXPIRATION_DATE = @ExpireDate
		WHERE SERVICE_AGREEMENT_ID = @SAId AND (EXPIRATION_DATE IS NULL OR EXPIRATION_DATE > @ExpireDate);
		
		SET @countCM  = (SELECT COUNT(*) FROM CHARGE_MASTER WHERE SERVICE_AGREEMENT_ID = @SAId AND EXPIRATION_DATE = @ExpireDate);
		PRINT('Resulting CM Count for SAId  = ' + CAST(@countCM AS varchar(20)));
	END
	ELSE
	BEGIN
		PRINT('No Charge Master Records to process for SAId ' + CAST(@SAId AS VARCHAR(20)) );
	END;


	PRINT('------------------------------------------');
	PRINT('     Processing complete for SAId: ' + CAST(@SAId AS VARCHAR(20)));
	PRINT('------------------------------------------');
	--SELECT 'Processing complete for SAId' = CAST(@SAId AS VARCHAR(20));
END

GO
