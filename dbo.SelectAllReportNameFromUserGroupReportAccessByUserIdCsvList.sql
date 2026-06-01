SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
CREATE   PROCEDURE [dbo].[SelectAllReportNameFromUserGroupReportAccessByUserIdCsvList]
	@CsvListGroupIds varchar(4000)
AS
BEGIN
 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @CsvListGroupIds IS NULL OR LEN(@CsvListGroupIds) <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;
	
	DECLARE @dos datetime = getdate();
	
	-- load temp table with csv data
	DECLARE @tempUserGroupIds TABLE
	(
		UGID INT
	);

	INSERT @tempUserGroupIds(UGID)
		SELECT 
			CAST(RTRIM(LTRIM(value)) AS INT) AS UGID
		FROM STRING_SPLIT (@CsvListGroupIds, ',')
	
	-- select * from @tempUserGroupIds -- testing

	DECLARE @countToProcess INT = (SELECT COUNT(*) FROM @tempUserGroupIds);

	IF @countToProcess <= 0
	BEGIN
		SELECT Result = NULL;
		RETURN;
	END;

	SELECT DISTINCT [ReportName]
	FROM [dbo].[UserGroupReportAccess]
	WHERE ([ExpirationDate] IS NULL OR [ExpirationDate] > @dos )
		AND [EffectiveDate] <= @dos
		AND [UserGroupId] IN (SELECT DISTINCT UGID FROM @tempUserGroupIds)
	

END; -- end of stored procedure

GO
