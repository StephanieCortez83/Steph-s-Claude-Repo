SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   PROCEDURE [dbo].[Maintenance_FindTop100ElmahErrorXmlContainingSearchString] 
	    @SearchString VARCHAR(256)
	  , @allFields BIT = 0
WITH EXEC AS CALLER AS
BEGIN
	----------------
	-- validate parameters
	----------------
	IF @SearchString IS NULL OR LEN(@SearchString) <= 0
	BEGIN
		RETURN;
	END;

	SET @SearchString = '%' + @SearchString + '%';

	-- For speed reasons, limit the search to last 90 .  does not have to be perfect
	DECLARE @testDate1 DATETIME = DATEADD(day, -90, GETDATE());
	DECLARE @sequenceMinimum INT = (SELECT TOP 1 [SEQUENCE] FROM [ELMAH_ERROR] WHERE [TIMEUTC] >= @testDate1 ORDER BY [SEQUENCE] ASC)

	IF @sequenceMinimum IS NULL 
		SET @sequenceMinimum = 0;

	-- setup resources
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @allFields = 1
		SELECT TOP 100 
			*
		FROM 
			[ELMAH_ERROR]
		WHERE 
			[Type] = 'System.NullReferenceException'
			AND [SEQUENCE] >= @sequenceMinimum
			AND [TIMEUTC] >= @testDate1
			AND [ALLXML] LIKE @SearchString
		ORDER BY 
			[TIMEUTC] DESC;
	ELSE

	SELECT TOP 100 
		  [ErrorId]
		, [Message]
	FROM 
		[ELMAH_ERROR]
	WHERE 
		[Type] = 'System.NullReferenceException'
		AND [SEQUENCE] >= @sequenceMinimum
		AND [TIMEUTC] >= @testDate1
		AND [ALLXML] LIKE @SearchString
	ORDER BY 
		[TIMEUTC] DESC;

END -- end procedure

GO
