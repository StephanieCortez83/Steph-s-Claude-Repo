SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Maintenance_BackupTable]
      @SrcTable VARCHAR(512)
	, @DestTable VARCHAR(512)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @SrcTable IS NULL OR LEN(@SrcTable) <= 0
	BEGIN
		SELECT 'ERROR' = '@SrcTable is invalid';
		RETURN;
	END;

	IF @DestTable IS NULL OR LEN(@DestTable) <= 0
	BEGIN
		SELECT 'ERROR' = '@DestTable is invalid';
		RETURN;
	END;

	DECLARE @Nsql   NVARCHAR(MAX),
		    @Result INT;
			
	-- see if the source table has any data
	SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@SrcTable);
	-- PRINT(N'@countSource SQL :: ' + @Nsql)

	EXEC sp_executesql
		  @Nsql,
		  N'@Result INT OUTPUT',
		  @Result = @Result OUTPUT; 

	DECLARE @countSource INT = @Result;
	PRINT(' @countSource: ' + CAST(@countSource AS varchar(50)));

	IF @countSource <= 0
	BEGIN
		SELECT 'ERROR' = 'No Records in Source Table[' + @SrcTable + '].  Exiting';
		RETURN;
	END;


	-- see if the destination table exists
	SET @Nsql = N'SELECT @Result = COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = ''dbo'' AND TABLE_NAME = ''' + @DestTable + '''';
	-- PRINT(N'backup table exists SQL :: ' + @Nsql)

	EXEC sp_executesql
		  @Nsql,
		  N'@Result INT OUTPUT',
		  @Result = @Result OUTPUT; 

	-- PRINT(' @Result: ' + CAST(@Result AS varchar(50)));

	IF(@Result > 0)
	BEGIN
		SELECT 'ERROR' = '@DestTable [' + @DestTable + '] backup already exists.  adjust and re-run procedure.'
		RETURN;
	END;

	print (' backing up ' + QUOTENAME(@SrcTable) + ' to ' + QUOTENAME(@DestTable));

	SET @Nsql = N'SELECT * INTO ' + QUOTENAME(@DestTable) + ' FROM ' + QUOTENAME(@SrcTable);
	PRINT(N'backup table SQL :: ' + @Nsql)
	EXEC sp_executesql @Nsql;


	-- see if the destination table has any data
	SET @Nsql = N'SELECT @Result = COUNT(*) FROM ' + QUOTENAME(@DestTable);
	-- PRINT(N'@countDestination SQL :: ' + @Nsql)

	EXEC sp_executesql
		  @Nsql,
		  N'@Result INT OUTPUT',
		  @Result = @Result OUTPUT; 

	DECLARE @countDestination INT = @Result;
	-- PRINT(' @countDestination: ' + CAST(@countDestination AS varchar(50)));

	IF @countSource <> @countDestination
	BEGIN
		SELECT 'ERROR' = 'Source table count does not equal the backup table count[ ' + CAST(@countSource AS varchar(50)) + ' : ' + CAST(@countDestination AS varchar(50)) + '].  Exiting';
		RETURN;
	END;

	SELECT 'SUCCESS' = ' [' + @SrcTable + ':' + CAST(@countSource AS VARCHAR(50)) + '] Copied to [' + @DestTable + ':' + CAST(@countDestination AS VARCHAR(50)) + ']';

END
GO
