SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE   PROCEDURE [dbo].[Maintenance_BackupProcedureAndDrop]
      @SrcProc VARCHAR(512)
	, @DestProc VARCHAR(512) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		IF @SrcProc IS NULL OR LEN(@SrcProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@SrcProc is invalid';
			RETURN;
		END;

		IF @DestProc IS NULL
		BEGIN
			DECLARE @dos DATETIME = GETDATE();
			DECLARE @Suf VARCHAR(40) = 
			(
				SELECT SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 1,4) 
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 6, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 9, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 12, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 15, 2)
				+ SUBSTRING(CONVERT(VARCHAR(30), @dos, 120), 18, 2)
			);  

			SET @DestProc = @SrcProc + '_' + @Suf;
			PRINT('setting @DestProc to: ' + @DestProc);
		END;

		IF @DestProc IS NULL OR LEN(@DestProc) <= 0
		BEGIN
			SELECT 'ERROR' = '@DestProc is invalid';
			RETURN;
		END;
				
		IF LOWER(RTRIM(@DestProc)) = LOWER(RTRIM(@SrcProc))
		BEGIN
			SELECT 'ERROR' = '@SrcProc and @DestProc can NOT be the same';
			RETURN;
		END;

		-- see if we can find the stored procedure
		DECLARE @defProc NVARCHAR(MAX) = 
		(
			SELECT 
				m.definition
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @SrcProc
		);

		IF @defProc IS NULL OR LEN(@defProc) <= 0
		BEGIN
			SELECT 'ERROR' = 'Procedure [' + @SrcProc + '] does NOT exist';
			RETURN;
		END;
		
		-- PRINT('@defProc = ' + @defProc);

		-- copy it
		-- fix SPROC target name
		SET @defProc = REPLACE(@defProc, @SrcProc, @DestProc);
		-- fix the single quotes that may occur within the SPROC
		SET @defProc = REPLACE(@defProc, '''','''''');
		--PRINT('@defProc fixed = ' + @defProc);

		DECLARE @nSql NVARCHAR(MAX) = 'EXEC(''' + @defProc + ''')';
		PRINT('Executing: ' + @nSql);
		EXEC(@nSql);

		-- make sure new proc exists
		SET @defProc = 
		(
			SELECT 
				p.[name]
			FROM 
				sys.procedures p
				JOIN sys.sql_modules m ON p.OBJECT_ID = m.OBJECT_ID
			WHERE 
				[name] LIKE @DestProc
		);

		IF @defProc IS NULL
		BEGIN
			SELECT 'ERROR' = 'Copied Procedure [' + @DestProc + '] does NOT exist';
			RETURN;
		END;
		
		IF @defProc <> @DestProc
		BEGIN
			SELECT 'ERROR' = ' [' + @defProc + '] does NOT match [' + @DestProc + ']';
			RETURN;
		END;

	END TRY
	BEGIN CATCH
		SELECT 'ERROR' = 'Exception copying procedure: ' + CAST(ERROR_MESSAGE() AS VARCHAR(512));
		RETURN;
	END CATCH;


	BEGIN TRY

		SET @nSql = 'DROP PROCEDURE ' + @SrcProc + ';';
		PRINT('Executing: ' + @nSql);
		EXEC(@nSql);

		SELECT 'SUCCESS' = ' [' + @SrcProc + '] Copied to [' + @DestProc + '] and dropped.';

	END TRY
	BEGIN CATCH
		SELECT 'ERROR' = 'Exception dropping procedure: ' + CAST(ERROR_MESSAGE() AS VARCHAR(512));
		RETURN;
	END CATCH;

END
GO
