SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_ExpireCmsPqriMeasureCodeByPqriMeasureId]
      @PqriMeasureId INT
	, @ExpireDate DATE
	, @SkipDateNullCheck BIT = 0
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
	IF @SkipDateNullCheck = 1
		UPDATE [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE]
		SET [END_DATE] = @ExpireDate
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
	ELSE
		UPDATE [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE]
		SET [END_DATE] = @ExpireDate
		WHERE 
			[CMS_PQRI_MEASURE_ID] = @PqriMeasureId
			AND [END_DATE] IS NULL
	DECLARE @countResult INT = (SELECT Count (*) FROM [CMSRules].[dbo].[CMS_PQRI_MEASURE_CODE] WHERE [CMS_PQRI_MEASURE_ID] = @PqriMeasureId AND [END_DATE] = @ExpireDate)
	SELECT 'RESULT' = 'CMS PQRI Measure ID [' + CAST(@PqriMeasureId AS VARCHAR(30)) + '] expired to [' + CAST(@ExpireDate AS VARCHAR(30)) + '] count = ' + CAST(@countResult AS VARCHAR(30));
END
GO
