----------------------------------------------------
-- 02) DACS-2872 - Stored Procedure - Maintenance_InsertICD_10_DIRECT_PICK.SQL
----------------------------------------------------
USE [RevCycleDB]
GO

CREATE OR ALTER PROCEDURE [dbo].[Maintenance_InsertICD_10_DIRECT_PICK]  
	  @Icd10Code AS VARCHAR(10)
	, @DirectPickType AS INT
	, @SequenceNumber AS INT
	, @ShortDescription AS VARCHAR(100)
	, @LongDescription AS VARCHAR(500)
	, @EffectiveDate AS DATETIME
	, @ExpirationDate AS DATETIME = '12-31-2099'
AS  
BEGIN    
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Icd10Code IS NULL OR LEN(@Icd10Code) <= 0 OR LEN(@Icd10Code) > 10
	BEGIN
		PRINT('@Icd10Code is invalid');
		SELECT 'Result' = '@Icd10Code is invalid';
		RETURN;
	END;
	
	IF @ShortDescription IS NULL OR LEN(@ShortDescription) <= 0 OR LEN(@ShortDescription) > 100
	BEGIN
		PRINT('@ShortDescription is invalid');
		SELECT 'Result' = '@ShortDescription is invalid';
		RETURN;
	END;

	IF @LongDescription IS NULL OR LEN(@LongDescription) > 500
	BEGIN
		PRINT('Setting LongDescription to ShortDescription.');
		SET @LongDescription = @ShortDescription;
	END;
	
	IF @EffectiveDate IS NULL
	BEGIN
		PRINT('Setting EffectiveDate to now.');
		SET @EffectiveDate = GETDATE();
	END;

	IF @ExpirationDate IS NULL
	BEGIN
		PRINT('Setting ExpirationDate to 12-31-2099.');
		SET @ExpirationDate ='12-31-2099';
	END;

	DECLARE @foundCount INT = ( 
		SELECT COUNT(*) 
		FROM 
			[dbo].[ICD_10_DIRECT_PICK] 
		WHERE 
			[ICD_10_CODE] = @Icd10Code 
			AND [EFFECTIVE_DATE] <= @EffectiveDate
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate)
		);

	IF @foundCount > 0
	BEGIN
		PRINT('This record already exists in the table.  Exiting.');
		SELECT 'Result' = 'This record already exists in the table.  Exiting.';
		RETURN;
	END;
	

	INSERT INTO [dbo].[ICD_10_DIRECT_PICK]
	(
		  [ICD_10_CODE]
		, [DIRECT_PICK_TYPE]
		, [SEQUENCE_NUMBER]
		, [SHORT_DESCRIPTION]
		, [LONG_DESCRIPTION]
		, [EFFECTIVE_DATE]
		, [EXPIRATION_DATE]
	)
	VALUES
	(	  @Icd10Code
		, @DirectPickType
		, @SequenceNumber
		, @ShortDescription
		, @LongDescription
		, @EffectiveDate
		, @ExpirationDate
	)

	SET @foundCount = ( 
		SELECT COUNT(*) 
		FROM 
			[dbo].[ICD_10_DIRECT_PICK] 
		WHERE 
			[ICD_10_CODE] = @Icd10Code 
			AND [EFFECTIVE_DATE] <= @EffectiveDate
			AND ([EXPIRATION_DATE] IS NULL OR [EXPIRATION_DATE] >= @ExpirationDate)
		);

	IF @foundCount <= 0
	BEGIN
		PRINT('Failed to insert record.');
		SELECT 'Result' = 'Failed to insert record.';
		RETURN;
	END;

	PRINT('SUCCESS');
	SELECT 'Result' = 'SUCCESS'; 

END

GO

/*
testing
begin tran;
exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = 'testing', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022', @ExpirationDate = '12-30-2099'

exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = '', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022'

exec [dbo].[Maintenance_InsertICD_10_DIRECT_PICK] @Icd10Code = 'sdfsdfsdf', @DirectPickType = 1, @SequenceNumber = 77
	, @ShortDescription = 'testing short', @LongDescription = 'testing long', @EffectiveDate = '01-01-2022'

select top 10 * from [dbo].[ICD_10_DIRECT_PICK] order by ICD_10_DIRECT_PICK_ID desc;
rollback tran;
*/
