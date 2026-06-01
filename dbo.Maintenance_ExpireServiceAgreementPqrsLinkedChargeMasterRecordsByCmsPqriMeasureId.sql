SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ExpireServiceAgreementPqrsLinkedChargeMasterRecordsByCmsPqriMeasureId]
      @PqriMeasureId INT
	, @ExpireDate DATE  -- Expiration date must match within [SERVICE_AGREEMENT_PQRS] table to find deletion matches in [CHARGE_MASTER] Table
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @PqriMeasureId IS NULL OR @PqriMeasureId <= 0
	BEGIN
		SELECT 'ERROR' = '@PqriMeasureId is invalid';
		RETURN;
	END;

	IF @ExpireDate IS NULL
	BEGIN
		SELECT 'ERROR' = '@ExpireDate is invalid';
		RETURN;
	END;

	UPDATE [CHARGE_MASTER] 
	SET [EXPIRATION_DATE] = @ExpireDate
	WHERE 
		[CHARGE_MASTER_USAGE_CODE] = 9 -- 9 =	PQRS Option
		AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpireDate)
		AND [SERVICE_AGREEMENT_ID] IN 
			(
				SELECT DISTINCT [SERVICE_AGREEMENT_ID] 
				FROM 
					[SERVICE_AGREEMENT_PQRS] 
				WHERE 
					[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
					AND [EXPIRATION_DATE] = @ExpireDate
			)
		AND [CPT_CODE] IN
			(
				SELECT DISTINCT [CODE] 
				FROM 
					[CMS_PQRI_MEASURE_CODE] 
				WHERE 
					[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
					AND ([CODE] IS NOT NULL AND [CODE] NOT LIKE '%.%' AND LEN([CODE]) = 5)
			)


	DECLARE @countResult INT = 
		(
			SELECT COUNT(*) 
				FROM [CHARGE_MASTER] 
			
			WHERE
				[EXPIRATION_DATE] = @ExpireDate
				AND [CHARGE_MASTER_USAGE_CODE] = 9 -- 9 =	PQRS Option
				AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpireDate)
				AND [SERVICE_AGREEMENT_ID] IN 
					(
						SELECT DISTINCT [SERVICE_AGREEMENT_ID] 
						FROM 
							[SERVICE_AGREEMENT_PQRS] 
						WHERE 
							[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
							AND [EXPIRATION_DATE] = @ExpireDate
					)
				AND [CPT_CODE] IN
					(
						SELECT DISTINCT [CODE] 
						FROM 
							[CMS_PQRI_MEASURE_CODE] 
						WHERE 
							[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
							AND ([CODE] IS NOT NULL AND [CODE] NOT LIKE '%.%' AND LEN([CODE]) = 5)
					)
		);

	SELECT 'RESULT' = 'CM Entries for CMS PQRI Measure ID [' + CAST(@PqriMeasureId AS VARCHAR(30)) + '] expired to [' + CAST(@ExpireDate AS VARCHAR(30)) + '] count = ' + CAST(@countResult AS VARCHAR(30));

END
GO
