SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[InsertElmahWarmupEntryByEventAndAppNameAndUrl] 
	 @Event VARCHAR(32)
	,@AppName VARCHAR(60)
	,@Url VARCHAR(30)
	,@WarmupSeconds INT = NULL
WITH EXEC AS CALLER AS
BEGIN
	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	----------------
	-- validate parameters
	----------------
	IF @Event IS NULL OR RTRIM(@Event) NOT IN ('Startup','Warmup')
	BEGIN 
		PRINT('@Event is invalid.  Exiting.');
		SELECT 'Result' = '-1'
		RETURN
	END;
	
	DECLARE @UNIQUEX UNIQUEIDENTIFIER = NEWID();
	DECLARE @NowUtc DATETIME = GETUTCDATE();
	DECLARE @LogMsg VARCHAR(256) = 'Startup for ' + @Url + ' at ' + CAST(@NowUtc AS VARCHAR(60));

	IF @WarmupSeconds IS NOT NULL
		SET @LogMsg = 'Warmup completed succesfully in ' + CAST(@WarmupSeconds AS VARCHAR(64)) + ' seconds.';

	DECLARE @AllXml VARCHAR(300) = '<error message="' + @LogMsg + '" >  </error>';

	EXEC [dbo].[ELMAH_LogError]
		@ErrorId = @UNIQUEX,
		@Application = @AppName,
		@Host = @Url,
		@Type = @Event,
		@Source = '_Warmup.aspx',
		@Message = @LogMsg,
		@User = 'Automated',
		@AllXml = @AllXml,
		@StatusCode = 200,
		@TimeUtc = @NowUtc;

	SELECT CAST([ErrorId] as VARCHAR(100)) FROM [ELMAH_Error] WITH (NOLOCK) WHERE [ErrorId] = @UNIQUEX;

/*
	----------------
	-- Replaces the following ACS inline SQL:
	----------------
	\CCSWebApp\WebPages\_Warmup.aspx.cs: Page_Load(...)
	var sql = $@"DECLARE @UNIQUEX UNIQUEIDENTIFIER;
					SET @UNIQUEX = NEWID();
					DECLARE @NowUtc DATETIME;
					SET @NowUtc = GETUTCDATE();

					EXEC [dbo].[ELMAH_LogError]
						@ErrorId = @UNIQUEX,
						@Application = '{AppConfiguration.Instance().ApplicationName.TakeFirst(60)}',
						@Host = '{AppConfiguration.Instance().WebsiteURL.Replace("https://", string.Empty).TakeFirst(30)}',
						@Type = 'Startup',
						@Source = '_Warmup.aspx',
						@Message = 'Startup for {AppConfiguration.Instance().WebsiteURL.Replace("https://", string.Empty).TakeFirst(30)} at {DateTime.Now}',
						@User = 'Automated',
						@AllXml = 'Startup for {AppConfiguration.Instance().WebsiteURL.Replace("https://", string.Empty).TakeFirst(30)} at {DateTime.Now}',
						@StatusCode = 200,
						@TimeUtc = @NowUtc;

					SELECT CAST([ErrorId] as VARCHAR(100)) FROM [ELMAH_Error] WITH (NOLOCK) WHERE [ErrorId] = @UNIQUEX;";

	AND
	var sql = $@"DECLARE @UNIQUEX UNIQUEIDENTIFIER;
						SET @UNIQUEX = NEWID();
						DECLARE @NowUtc DATETIME;
						SET @NowUtc = GETUTCDATE();

						EXEC [dbo].[ELMAH_LogError]
							@ErrorId = @UNIQUEX,
							@Application = '{AppConfiguration.Instance().ApplicationName.TakeFirst(60)}',
							@Host = '{AppConfiguration.Instance().WebsiteURL.Replace("https://", string.Empty).TakeFirst(30)}',
							@Type = 'Warmup',
							@Source = '_Warmup.aspx',
							@Message = 'Warmup completed succesfully in {_stopwatch.Elapsed.TotalSeconds} seconds.',
							@User = 'Automated',
							@AllXml = 'Warmup completed succesfully in {_stopwatch.Elapsed.TotalSeconds} seconds.',
							@StatusCode = 200,
							@TimeUtc = @NowUtc;

						SELECT COUNT(*) FROM [ELMAH_Error] WITH (NOLOCK) WHERE [ErrorId] = @UNIQUEX;";	
*/	
END -- end procedure

GO
